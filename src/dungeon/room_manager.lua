local DungeonManager = require("dungeon_manager")
local RoomManager = Class("RoomManager"):include(Stateful)

-- Helper: Place door sprites with optional temp offset
-- offset_x/y are RELATIVE to the room's canonical world position
local function apply_door_sprites_at_offset(room, offset_x, offset_y)
    if not room.doors then return end
    offset_x = offset_x or 0
    offset_y = offset_y or 0

    for dir, door in pairs(room.doors) do
        local pos = room:get_door_tile(dir)
        if pos then
            mset(pos.tx + offset_x, pos.ty + offset_y, door.sprite)
        end
    end
end

-- Helper: Carve room at offset position for transition animation
-- offset_x/y are RELATIVE to the room's canonical world position
local function carve_room_at_offset(room, offset_x, offset_y)
    local wall_options = {1, 2}
    offset_x = offset_x or 0
    offset_y = offset_y or 0

    -- Fill area with walls
    local bounds = room:get_bounds()
    for ty = bounds.y1, bounds.y2 do
        for tx = bounds.x1, bounds.x2 do
            local sprite = wall_options[1]
            if #wall_options > 1 and rnd() < 0.1 then
                sprite = wall_options[flr(rnd(#wall_options - 1)) + 2]
            end
            mset(tx + offset_x, ty + offset_y, sprite)
        end
    end

    -- Carve floor
    local floor = room:get_inner_bounds()
    for ty = floor.y1, floor.y2 do
        for tx = floor.x1, floor.x2 do
            mset(tx + offset_x, ty + offset_y, 0)
        end
    end

    -- Place doors at offset
    apply_door_sprites_at_offset(room, offset_x, offset_y)
end

local OPPOSITE_DIR = {
    north = "south",
    south = "north",
    east = "west",
    west = "east"
}

-- State: Exploring
local Exploring = RoomManager:addState("Exploring")

function Exploring:enteredState()
    Log.trace("Entered Exploring state")
end

function Exploring:update(world, player)
    local room = DungeonManager.current_room
    if not room then return end

    -- Check room clear
    if room.is_locked and room.spawned then
        local enemy_count = 0
        world.sys("enemy", function(e)
            if not e.dead then enemy_count += 1 end
        end)()

        if enemy_count == 0 then
            room:unlock()
            DungeonManager.update_door_sprites(room)
        end
    end

    -- Update spawner
    local Systems = require("systems")
    Systems.Spawner.update(world, room)

    -- "Edge trigger" logic: Doors only work after you've stepped off them at least once
    if not player.door_trigger then
        player.is_door_active = true
    end

    -- Check for door trigger (only if it has been activated by leaving a door)
    if player.door_trigger and player.is_door_active then
        local door_dir = player.door_trigger
        player.door_trigger = nil
        player.is_door_active = false -- Reset for next room entry
        self:gotoState("Scrolling", world, player, door_dir)
    end
end

function Exploring:exitedState()
    Log.trace("Exited Exploring state")
end

-- State: Scrolling
local Scrolling = RoomManager:addState("Scrolling")

function Scrolling:enteredState(world, player, door_dir)
    Log.trace("Entered Scrolling state, direction: "..door_dir)

    self.door_direction = door_dir
    self.world = world
    self.player = player
    self.scroll_timer = 0
    self.scroll_duration = 30 -- frames (0.5s at 60fps)

    -- Freeze player
    self.player_frozen = true
    self.saved_vel_x = player.vel_x
    self.saved_vel_y = player.vel_y
    player.vel_x = 0
    player.vel_y = 0

    -- Calculate camera movement based on actual room dimensions.
    -- We want the rooms to appear adjacent (walls touching) during the scroll.
    -- The offset is calculated so the next room's wall touches the current room's wall.
    local current_room = DungeonManager.current_room
    local next_room = DungeonManager.peek_next_room(door_dir)

    -- If there's no room in this direction, abort the transition
    if not next_room then
        Log.trace("No room in direction: "..door_dir..", aborting transition")
        self:gotoState("Exploring")
        return
    end

    local current_ox, current_oy = 0, 0
    local next_ox, next_oy = 0, 0

    if door_dir == "east" or door_dir == "south" then
        -- East/South: Current room stays at 0,0. Next room is offset.
        next_ox, next_oy = self:getAlignmentOffset(current_room, next_room, door_dir)
        self.camera_start = {x = 0, y = 0}
        self.camera_target = {x = next_ox * GRID_SIZE, y = next_oy * GRID_SIZE}
    else
        -- West/North: Next room stays at 0,0. Current room is offset.
        -- We place the current room on the opposite side of the next room.
        local opposite = OPPOSITE_DIR[door_dir]
        current_ox, current_oy = self:getAlignmentOffset(next_room, current_room, opposite)
        self.camera_start = {x = current_ox * GRID_SIZE, y = current_oy * GRID_SIZE}
        self.camera_target = {x = 0, y = 0}
    end

    self.camera_offset = {x = self.camera_start.x, y = self.camera_start.y}

    -- Store room references and their pixel offsets for drawing floors
    self.current_room = current_room
    self.next_room = next_room
    self.current_room_offset = {x = current_ox * GRID_SIZE, y = current_oy * GRID_SIZE}
    self.next_room_offset = {x = next_ox * GRID_SIZE, y = next_oy * GRID_SIZE}

    -- Offset player position to match the current room's offset
    -- This keeps the player visually in the correct room during the scroll
    player.x = player.x + self.current_room_offset.x
    player.y = player.y + self.current_room_offset.y

    -- Cleanup old room entities
    world.sys("projectile", function(e) world.del(e) end)()
    world.sys("pickup", function(e) world.del(e) end)()
    world.sys("skull", function(e) world.del(e) end)()

    -- Clear map and carve both rooms at their respective offsets
    DungeonManager.clear_map()
    carve_room_at_offset(current_room, current_ox, current_oy)
    if next_room then
        carve_room_at_offset(next_room, next_ox, next_oy)
    end
end

function Scrolling:update(world, player)
    self.scroll_timer += 1
    local progress = self.scroll_timer / self.scroll_duration
    progress = min(progress, 1)

    local ease_t = progress < 0.5
       and 2 * progress * progress
       or 1 - ((-2 * progress + 2) ^ 2) / 2

    self.camera_offset = {
        x = self.camera_start.x + (self.camera_target.x - self.camera_start.x) * ease_t,
        y = self.camera_start.y + (self.camera_target.y - self.camera_start.y) * ease_t
    }

    if progress >= 1 then
        self:gotoState("Settling")
    end
end

function Scrolling:exitedState()
    Log.trace("Exited Scrolling state")
end

-- State: Settling
local Settling = RoomManager:addState("Settling")

function Settling:enteredState()
    Log.trace("Entered Settling state")

    -- 1. Restore player world coordinates (remove temporary scroll offset)
    local ox = self.current_room_offset and self.current_room_offset.x or 0
    local oy = self.current_room_offset and self.current_room_offset.y or 0
    local original_player_x = self.player.x - ox
    local original_player_y = self.player.y - oy

    -- 2. Commit room transition in DungeonManager
    local prev_room = DungeonManager.current_room
    local next_room = DungeonManager.enter_door(self.door_direction)

    if next_room then
        -- 3. Prepare visual continuity (the "peek" effect)
        -- Place previous room aligned to the entrance side of the new room
        local entrance_side = OPPOSITE_DIR[self.door_direction]
        local prev_ox, prev_oy = self:getAlignmentOffset(next_room, prev_room, entrance_side)

        DungeonManager.clear_map()
        DungeonManager.carve_room(next_room)
        carve_room_at_offset(prev_room, prev_ox, prev_oy)

        -- 4. Position player in new room
        local spawn_pos = DungeonManager.calculate_spawn_position(
            self.door_direction,
            next_room,
            original_player_x,
            original_player_y
        )
        self.player.x = spawn_pos.x
        self.player.y = spawn_pos.y

        -- 5. Initialize room content
        self:setupRoom(next_room)
    end

    -- 6. Cleanup transition state
    self:finalizeTransition()

    -- 7. Resume gameplay
    self:gotoState("Exploring")
end

-- RoomManager instance methods
function RoomManager:update(world, player)
    -- Defined so that stateful can delegate to the active state
end

function RoomManager:initialize(world, player)
    self.world = world
    self.player = player

    -- Populate initial room
    local room = DungeonManager.current_room
    if room then
        self:setupRoom(room)
    end

    self:gotoState("Exploring")
end

-- Refactored Helpers --

-- Calculates tile offset to place 'target' room on a specific 'side' of 'ref' room
-- side: "north", "south", "east", "west"
function RoomManager:getAlignmentOffset(ref, target, side)
    local ox, oy = 0, 0
    if side == "north" then
        -- target is above ref -> target's bottom wall at ref's top wall
        oy = (ref.tiles.y - target.tiles.h + 1) - target.tiles.y
    elseif side == "south" then
        -- target is below ref -> target's top wall at ref's bottom wall
        oy = (ref.tiles.y + ref.tiles.h - 1) - target.tiles.y
    elseif side == "east" then
        -- target is right of ref -> target's left wall at ref's right wall
        ox = (ref.tiles.x + ref.tiles.w - 1) - target.tiles.x
    elseif side == "west" then
        -- target is left of ref -> target's right wall at ref's left wall
        ox = (ref.tiles.x - target.tiles.w + 1) - target.tiles.x
    end
    return ox, oy
end

-- Initialize room contents (enemies, locks, timers)
function RoomManager:setupRoom(room)
    local Systems = require("systems")
    Systems.Spawner.populate(room, self.player)

    -- If enemies spawned, lock the room
    if #room.enemy_positions > 0 then
        room:lock()
        DungeonManager.update_door_sprites(room)
    end

    -- Restart skull timer if entering a cleared combat room
    if room.cleared and room.room_type == "combat" then
        room.skull_timer = SKULL_SPAWN_TIMER
        room.skull_spawned = false
    end
end

-- Reset camera, unfreeze player, and clear transition flags
function RoomManager:finalizeTransition()
    self.camera_offset = {x = 0, y = 0}

    -- Unfreeze player
    if self.player_frozen then
        self.player.vel_x = self.saved_vel_x or 0
        self.player.vel_y = self.saved_vel_y or 0
        self.player_frozen = false
    end

    -- Clear temporary state
    self.player.door_trigger = nil
    self.player.is_door_active = false
    self.current_room_offset = nil
    self.next_room_offset = nil
end

-- Getter for camera offset (returns WORLD pixel coordinates)
function RoomManager:getCameraOffset()
    local base = DungeonManager.get_base_camera_offset()
    local offset = self.camera_offset or {x = 0, y = 0}
    return {
        x = base.x + offset.x,
        y = base.y + offset.y
    }
end

-- Check if gameplay should be active
function RoomManager:isExploring()
    local stack = self:getStateStackDebugInfo()
    return stack and stack[1] == "Exploring"
end

-- Draw room floors (handles both exploring and scrolling states)
function RoomManager:drawRooms()
    if self:isExploring() then
        -- Normal: just draw the current room at its world position
        local room = DungeonManager.current_room
        if room then
            local rx = room.pixels.x
            local ry = room.pixels.y
            local rx2 = rx + room.pixels.w - 1
            local ry2 = ry + room.pixels.h - 1
            rectfill(rx, ry, rx2, ry2, room.floor_color)
        end
    else
        -- Scrolling: draw both rooms at their temporary world positions
        if self.current_room then
            local rx = self.current_room.pixels.x + self.current_room_offset.x
            local ry = self.current_room.pixels.y + self.current_room_offset.y
            local rx2 = rx + self.current_room.pixels.w - 1
            local ry2 = ry + self.current_room.pixels.h - 1
            rectfill(rx, ry, rx2, ry2, self.current_room.floor_color)
        end
        if self.next_room then
            local rx = self.next_room.pixels.x + self.next_room_offset.x
            local ry = self.next_room.pixels.y + self.next_room_offset.y
            local rx2 = rx + self.next_room.pixels.w - 1
            local ry2 = ry + self.next_room.pixels.h - 1
            rectfill(rx, ry, rx2, ry2, self.next_room.floor_color)
        end
    end
end

return RoomManager
