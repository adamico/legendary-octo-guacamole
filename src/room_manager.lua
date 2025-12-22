local DungeonManager = require("dungeon_manager")
local RoomManager = Class("RoomManager"):include(Stateful)

-- Helper: Place door sprites with offset (declared first for forward reference)
local function apply_door_sprites_at_offset(room, offset_x, offset_y)
    if not room.doors then return end

    local cx = room.tiles.x + flr(room.tiles.w / 2) + offset_x
    local cy = room.tiles.y + flr(room.tiles.h / 2) + offset_y

    if room.doors.north then
        mset(cx, room.tiles.y - 1 + offset_y, room.doors.north.sprite)
    end
    if room.doors.south then
        mset(cx, room.tiles.y + room.tiles.h + offset_y, room.doors.south.sprite)
    end
    if room.doors.west then
        mset(room.tiles.x + offset_x, cy, room.doors.west.sprite)
    end
    if room.doors.east then
        mset(room.tiles.x + room.tiles.w + offset_x, cy, room.doors.east.sprite)
    end
end

-- Helper: Carve room at offset position for transition animation
local function carve_room_at_offset(room, offset_x, offset_y)
    local wall_options = {1, 2}

    -- Fill area with walls
    local start_tx = room.tiles.x + offset_x
    local start_ty = room.tiles.y + offset_y

    for ty = 0, room.tiles.h do
        for tx = 0, room.tiles.w do
            local map_tx = start_tx + tx
            local map_ty = start_ty + ty
            local sprite = wall_options[1]
            if #wall_options > 1 and rnd() < 0.1 then
                sprite = wall_options[flr(rnd(#wall_options - 1)) + 2]
            end
            mset(map_tx, map_ty, sprite)
        end
    end

    -- Carve floor
    for ty = 1, room.tiles.h - 1 do
        for tx = 1, room.tiles.w - 1 do
            local map_tx = start_tx + tx
            local map_ty = start_ty + ty
            mset(map_tx, map_ty, 0)
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
            DungeonManager.unlock_room(room)
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

    -- Calculate camera target based on direction
    local target_x, target_y = 0, 0
    if door_dir == "east" then
        target_x = SCREEN_WIDTH
    elseif door_dir == "west" then
        target_x = -SCREEN_WIDTH
    elseif door_dir == "south" then
        target_y = SCREEN_HEIGHT
    elseif door_dir == "north" then
        target_y = -SCREEN_HEIGHT
    end

    self.camera_start = {x = 0, y = 0}
    self.camera_target = {x = target_x, y = target_y}
    self.camera_offset = {x = 0, y = 0}

    -- Cleanup old room entities
    world.sys("projectile", function(e) world.del(e) end)()
    world.sys("pickup", function(e) world.del(e) end)()

    -- Carve next room at offset position (transition-specific)
    local next_room = DungeonManager.peek_next_room(door_dir)
    if next_room then
        local offset_x = target_x / GRID_SIZE
        local offset_y = target_y / GRID_SIZE
        carve_room_at_offset(next_room, offset_x, offset_y)
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

    -- Commit room transition
    local next_room = DungeonManager.enter_door(self.door_direction)

    if next_room then
        -- Re-carve new room at (0,0)
        DungeonManager.clear_map()
        DungeonManager.carve_room(next_room)

        -- Teleport player to appropriate position (preserving cross-axis coordinate)
        local spawn_pos = DungeonManager.calculate_spawn_position(
            self.door_direction,
            next_room,
            self.player.x,
            self.player.y
        )
        self.player.x = spawn_pos.x
        self.player.y = spawn_pos.y

        -- Spawn enemies automatically for combat rooms
        DungeonManager.populate_enemies(next_room, self.player, nil, 80)
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
function RoomManager:initialize(world, player)
    self.world = world
    self.player = player
    self:gotoState("Exploring")
end

-- Getter for camera offset (used in Play:draw)
function RoomManager:getCameraOffset()
    return self.camera_offset or {x = 0, y = 0}
end

-- Check if gameplay should be active
function RoomManager:isExploring()
    local stack = self:getStateStackDebugInfo()
    return stack and stack[1] == "Exploring"
end

return RoomManager
