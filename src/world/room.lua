local machine = require("lib/lua-state-machine/statemachine")

--- @class RoomBounds
--- @field x number
--- @field y number
--- @field w number
--- @field h number

--- @class RoomLifecycle
--- @field is fun(self: RoomLifecycle, state: string): boolean
--- @field enter fun(self: RoomLifecycle)
--- @field spawn fun(self: RoomLifecycle)
--- @field clear fun(self: RoomLifecycle)

--- @class RoomDoor
--- @field sprite number
--- @field direction string

--- @class Room
--- @field tiles RoomBounds
--- @field pixels RoomBounds
--- @field enemy_positions table<integer, {x: number, y: number, type: string}>
--- @field lifecycle RoomLifecycle
--- @field doors? table<string, RoomDoor>
--- @field combat_timer? number
--- @field skull_timer? number
--- @field skull_spawned? boolean
--- @field skull_entity? EntityID
--- @field room_type? string
--- @field layout? {name: string, grid: string[]}
--- @field contents_config? {wave_pattern?: table, enemies?: table}
--- @field spawn_timer? number
--- @field shop_items? table
--- @field get_bounds fun(self: Room): {x1: number, y1: number, x2: number, y2: number}
--- @field get_inner_bounds fun(self: Room): {x1: number, y1: number, x2: number, y2: number}
--- @field get_center_tile fun(self: Room): {tx: number, ty: number}
--- @field get_door_tile fun(self: Room, direction: string): {tx: number, ty: number}|nil

local Room = Class("Room")

function Room:initialize(tx, ty, w, h, is_safe)
    self.tiles = {x = tx, y = ty, w = w, h = h}
    self.pixels = {
        x = tx * GRID_SIZE,
        y = ty * GRID_SIZE,
        w = w * GRID_SIZE,
        h = h * GRID_SIZE
    }

    self.enemy_positions = {}

    -- Lifecycle FSM
    local room = self
    self.lifecycle = machine.create({
        initial = is_safe and "empty" or "populated",
        events = {
            {name = "enter", from = "populated", to = "spawning"},
            {name = "spawn", from = "spawning",  to = "active"},
            {name = "clear", from = "active",    to = "cleared"},
        },
        callbacks = {
            onenterspawning = function()
                if room.doors then
                    for _, door in pairs(room.doors) do
                        door.sprite = DOOR_BLOCKED_TILE
                    end
                end
            end,
            onenteractive = function()
                room.combat_timer = 0
                if room.room_type == "combat" then
                    room.skull_timer = SKULL_SPAWN_LOCKED_TIMER
                    room.skull_spawned = false
                end
            end,
            onentercleared = function()
                room.combat_timer = -1
                if room.doors then
                    for _, door in pairs(room.doors) do
                        door.sprite = DOOR_OPEN_TILE
                    end
                end
                if room.room_type == "combat" then
                    room.skull_timer = SKULL_SPAWN_TIMER
                    room.skull_spawned = false
                end
            end,
        }
    })
end

function Room:get_bounds()
    return {
        x1 = self.tiles.x,
        y1 = self.tiles.y,
        x2 = self.tiles.x + self.tiles.w - 1,
        y2 = self.tiles.y + self.tiles.h - 1
    }
end

function Room:get_inner_bounds()
    return {
        x1 = self.tiles.x + 1,
        y1 = self.tiles.y + 1,
        x2 = self.tiles.x + self.tiles.w - 2,
        y2 = self.tiles.y + self.tiles.h - 2
    }
end

function Room:get_center_tile()
    return {
        tx = self.tiles.x + flr(self.tiles.w / 2),
        ty = self.tiles.y + flr(self.tiles.h / 2)
    }
end

function Room:get_door_tile(direction)
    local center = self:get_center_tile()
    local bounds = self:get_bounds()

    if direction == "north" then return {tx = center.tx, ty = bounds.y1} end
    if direction == "south" then return {tx = center.tx, ty = bounds.y2} end
    if direction == "west" then return {tx = bounds.x1, ty = center.ty} end
    if direction == "east" then return {tx = bounds.x2, ty = center.ty} end

    return nil
end

return Room
