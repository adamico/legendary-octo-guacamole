local Room = Class("Room")

function Room:initialize(tx, ty, w, h)
    self.tiles = {x = tx, y = ty, w = w, h = h}
    self.pixels = {
        x = tx * GRID_SIZE,
        y = ty * GRID_SIZE,
        w = w * GRID_SIZE,
        h = h * GRID_SIZE
    }

    self.floor_color = 5
end

-- Door Sprite Constants
local SPRITE_DOOR_OPEN = 3
local SPRITE_DOOR_BLOCKED = 4

function Room:lock()
    self.is_locked = true
    if self.doors then
        for _, door in pairs(self.doors) do door.sprite = SPRITE_DOOR_BLOCKED end
        -- We depend on DungeonManager to update the actual map tiles
        DungeonManager.update_door_sprites(self)
    end
end

function Room:unlock()
    self.is_locked = false
    self.cleared = true
    if self.doors then
        for _, door in pairs(self.doors) do door.sprite = SPRITE_DOOR_OPEN end
        DungeonManager.update_door_sprites(self)
    end
end

function Room:check_clear()
    if self.is_locked and #self.enemy_positions == 0 then
        self:unlock()
    end
end

-- Get outer boundaries in world tiles (inclusive)
function Room:get_bounds()
    return {
        x1 = self.tiles.x,
        y1 = self.tiles.y,
        x2 = self.tiles.x + self.tiles.w - 1,
        y2 = self.tiles.y + self.tiles.h - 1
    }
end

-- Get inner boundaries (world floor area) in tiles (inclusive)
function Room:get_inner_bounds()
    return {
        x1 = self.tiles.x + 1,
        y1 = self.tiles.y + 1,
        x2 = self.tiles.x + self.tiles.w - 2,
        y2 = self.tiles.y + self.tiles.h - 2
    }
end

-- Get world center tile coords
function Room:get_center_tile()
    return {
        tx = self.tiles.x + flr(self.tiles.w / 2),
        ty = self.tiles.y + flr(self.tiles.h / 2)
    }
end

-- Get world tile position for a door in a given direction
function Room:get_door_tile(direction)
    local center = self:get_center_tile()
    local bounds = self:get_bounds()

    if direction == "north" then return {tx = center.tx, ty = bounds.y1} end
    if direction == "south" then return {tx = center.tx, ty = bounds.y2} end
    if direction == "west" then return {tx = bounds.x1, ty = center.ty} end
    if direction == "east" then return {tx = bounds.x2, ty = center.ty} end

    return nil
end

-- Identify which door direction is at these world tile coords
function Room:identify_door(tx, ty)
    -- Check each door position directly
    for _, dir in ipairs({"north", "south", "east", "west"}) do
        local door_pos = self:get_door_tile(dir)
        if door_pos and door_pos.tx == tx and door_pos.ty == ty then
            return dir
        end
    end

    return nil
end

function Room:draw()
    self:draw_floor()
end

function Room:draw_floor()
    local rx = self.pixels.x
    local ry = self.pixels.y
    local rx2 = rx + self.pixels.w - 1
    local ry2 = ry + self.pixels.h - 1
    rectfill(rx, ry, rx2, ry2, self.floor_color)
end

return Room
