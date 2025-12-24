local machine = require("lua-state-machine/statemachine")
local Room = Class("Room")

function Room:initialize(tx, ty, w, h, is_safe)
    self.tiles = {x = tx, y = ty, w = w, h = h}
    self.pixels = {
        x = tx * GRID_SIZE,
        y = ty * GRID_SIZE,
        w = w * GRID_SIZE,
        h = h * GRID_SIZE
    }

    self.floor_color = 5

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
                        door.sprite = SPRITE_DOOR_BLOCKED
                    end
                end
            end,
            onentercleared = function()
                if room.doors then
                    for _, door in pairs(room.doors) do
                        door.sprite = SPRITE_DOOR_OPEN
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

function Room:identify_door(tx, ty)
    for _, dir in ipairs({"north", "south", "east", "west"}) do
        local door_pos = self:get_door_tile(dir)
        if door_pos then
            local dx, dy = 0, 0
            if dir == "east" then dx = 2 end
            if dir == "west" then dx = -2 end
            if dir == "north" then dy = -2 end
            if dir == "south" then dy = 2 end

            if door_pos.tx + dx == tx and door_pos.ty + dy == ty then
                return dir
            end
        end
    end

    return nil
end

function Room:draw(ox, oy)
    self:draw_floor(ox, oy)
    if self.lifecycle:is("cleared") or self.lifecycle:is("empty") then
        self:draw_corridors(ox, oy)
    end
end

function Room:draw_floor(ox, oy)
    ox = ox or 0
    oy = oy or 0
    local rx = self.pixels.x + ox
    local ry = self.pixels.y + oy
    local rx2 = rx + self.pixels.w - 1
    local ry2 = ry + self.pixels.h - 1
    rectfill(rx, ry, rx2, ry2, self.floor_color)
end

function Room:draw_corridors(ox, oy)
    if not self.doors then return end
    ox = ox or 0
    oy = oy or 0

    for dir, _ in pairs(self.doors) do
        local pos = self:get_door_tile(dir)
        if pos then
            local dx, dy = 0, 0
            if dir == "east" then dx = 1 end
            if dir == "west" then dx = -1 end
            if dir == "north" then dy = -1 end
            if dir == "south" then dy = 1 end

            local cx = pos.tx * GRID_SIZE + ox
            local cy = pos.ty * GRID_SIZE + oy

            if dx ~= 0 then
                local x1 = cx + (dx > 0 and GRID_SIZE or -CORRIDOR_LENGTH * GRID_SIZE)
                local y1 = cy
                local x2 = x1 + CORRIDOR_LENGTH * GRID_SIZE - 1
                local y2 = y1 + GRID_SIZE - 1
                rectfill(x1, y1, x2, y2, self.floor_color)
            else
                local x1 = cx
                local y1 = cy + (dy > 0 and GRID_SIZE or -CORRIDOR_LENGTH * GRID_SIZE)
                local x2 = x1 + GRID_SIZE - 1
                local y2 = y1 + CORRIDOR_LENGTH * GRID_SIZE - 1
                rectfill(x1, y1, x2, y2, self.floor_color)
            end
        end
    end
end

return Room
