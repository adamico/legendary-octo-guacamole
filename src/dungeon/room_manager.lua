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

    local current_offset_x, current_offset_y = 0, 0
    local next_offset_x, next_offset_y = 0, 0
    local scroll_distance_x, scroll_distance_y = 0, 0

    if door_dir == "east" then
        -- Place next room so its west wall OVERLAPS current room's east wall
        -- Subtract 1 to create overlap instead of adjacency
        next_offset_x = (current_room.tiles.x + current_room.tiles.w - 1) - next_room.tiles.x
        scroll_distance_x = next_offset_x * GRID_SIZE
        self.camera_start = {x = 0, y = 0}
        self.camera_target = {x = scroll_distance_x, y = 0}
    elseif door_dir == "west" then
        -- Place current room so its west wall OVERLAPS next room's east wall
        current_offset_x = (next_room.tiles.x + next_room.tiles.w - 1) - current_room.tiles.x
        scroll_distance_x = current_offset_x * GRID_SIZE
        self.camera_start = {x = scroll_distance_x, y = 0}
        self.camera_target = {x = 0, y = 0}
    elseif door_dir == "south" then
        -- Place next room so its north wall OVERLAPS current room's south wall
        next_offset_y = (current_room.tiles.y + current_room.tiles.h - 1) - next_room.tiles.y
        scroll_distance_y = next_offset_y * GRID_SIZE
        self.camera_start = {x = 0, y = 0}
        self.camera_target = {x = 0, y = scroll_distance_y}
    elseif door_dir == "north" then
        -- Place current room so its north wall OVERLAPS next room's south wall
        current_offset_y = (next_room.tiles.y + next_room.tiles.h - 1) - current_room.tiles.y
        scroll_distance_y = current_offset_y * GRID_SIZE
        self.camera_start = {x = 0, y = scroll_distance_y}
        self.camera_target = {x = 0, y = 0}
    end

    self.camera_offset = {x = self.camera_start.x, y = self.camera_start.y}

    -- Store room references and their pixel offsets for drawing floors
    self.current_room = current_room
    self.next_room = next_room
    self.current_room_offset = {x = current_offset_x * GRID_SIZE, y = current_offset_y * GRID_SIZE}
    self.next_room_offset = {x = next_offset_x * GRID_SIZE, y = next_offset_y * GRID_SIZE}

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
    carve_room_at_offset(current_room, current_offset_x, current_offset_y)
    if next_room then
        carve_room_at_offset(next_room, next_offset_x, next_offset_y)
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

    -- Remove the scroll offset from player position (it was added during Scrolling:enteredState)
    local original_player_x = self.player.x - (self.current_room_offset and self.current_room_offset.x or 0)
    local original_player_y = self.player.y - (self.current_room_offset and self.current_room_offset.y or 0)

    -- Remember the previous room before transitioning
    local prev_room = DungeonManager.current_room

    -- Commit room transition
    local next_room = DungeonManager.enter_door(self.door_direction)

    if next_room then
        -- Calculate the offset for showing the previous room at the edge
        -- Use the same alignment formula as the scroll (walls overlapping)
        local prev_offset_x, prev_offset_y = 0, 0
        if self.door_direction == "north" then
            -- Previous room was below, place its top wall at current room's bottom wall
            prev_offset_y = (next_room.tiles.y + next_room.tiles.h - 1) - prev_room.tiles.y
        elseif self.door_direction == "south" then
            -- Previous room was above, place its bottom wall at current room's top wall
            prev_offset_y = (next_room.tiles.y - prev_room.tiles.h + 1) - prev_room.tiles.y
        elseif self.door_direction == "east" then
            -- Previous room was left, place its right wall at current room's left wall
            prev_offset_x = (next_room.tiles.x - prev_room.tiles.w + 1) - prev_room.tiles.x
        elseif self.door_direction == "west" then
            -- Previous room was right, place its left wall at current room's right wall
            prev_offset_x = (next_room.tiles.x + next_room.tiles.w - 1) - prev_room.tiles.x
        end

        -- Clear map and carve new room at (0,0)
        DungeonManager.clear_map()
        DungeonManager.carve_room(next_room)

        -- Also carve the previous room at the edge (for visual continuity)
        carve_room_at_offset(prev_room, prev_offset_x, prev_offset_y)

        -- Teleport player to appropriate position (preserving cross-axis coordinate)
        local spawn_pos = DungeonManager.calculate_spawn_position(
            self.door_direction,
            next_room,
            original_player_x,
            original_player_y
        )
        self.player.x = spawn_pos.x
        self.player.y = spawn_pos.y

        -- Spawn enemies automatically for combat rooms
        local Systems = require("systems")
        Systems.Spawner.populate(next_room, self.player)

        if #next_room.enemy_positions > 0 then
            next_room:lock()
            DungeonManager.update_door_sprites(next_room)
        end

        -- Restart skull timer if entering a cleared combat room
        if next_room.cleared and next_room.room_type == "combat" then
            next_room.skull_timer = SKULL_SPAWN_TIMER
            next_room.skull_spawned = false
        end
    end

    -- Reset camera
    self.camera_offset = {x = 0, y = 0}

    -- Unfreeze player
    if self.player_frozen then
        self.player.vel_x = self.saved_vel_x or 0
        self.player.vel_y = self.saved_vel_y or 0
        self.player_frozen = false
    end

    -- Clear any door trigger and set active flag to false (must leave door footprint)
    self.player.door_trigger = nil
    self.player.is_door_active = false

    -- Immediately transition to exploring
    self:gotoState("Exploring")
end

-- RoomManager instance methods
function RoomManager:update(world, player)
    -- Defined so that stateful can delegate to the active state
end

function RoomManager:initialize(world, player)
    self.world = world
    self.player = player

    -- Populate initial room enemies
    local room = DungeonManager.current_room
    if room then
        local Systems = require("systems")
        Systems.Spawner.populate(room, player)

        -- If enemies spawned, lock the room
        if #room.enemy_positions > 0 then
            room:lock()
            DungeonManager.update_door_sprites(room)
        end
    end

    self:gotoState("Exploring")
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
