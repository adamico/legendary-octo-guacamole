local Room = Class("Room")

function Room:initialize(x, y, w, h, wall_options)
    self.tiles = {x = x, y = y, w = w, h = h}
    self.pixels = {
        x = x * GRID_SIZE,
        y = y * GRID_SIZE,
        w = w * GRID_SIZE,
        h = h * GRID_SIZE
    }

    self.floor_color = 5
    self.wall_options = wall_options or {1, 2}
    self:carve()
end

function Room:carve()
    local map_w = flr(SCREEN_WIDTH / GRID_SIZE)
    local map_h = flr(SCREEN_HEIGHT / GRID_SIZE)

    -- Fill screen with walls
    for ty = 0, map_h do
        for tx = 0, map_w do
            local sprite = self.wall_options[1]
            if #self.wall_options > 1 and rnd() < 0.1 then
                sprite = self.wall_options[flr(rnd(#self.wall_options - 1)) + 2]
            end
            mset(tx, ty, sprite)
        end
    end

    -- Carve floor
    for ty = self.tiles.y, self.tiles.y + self.tiles.h - 1 do
        for tx = self.tiles.x, self.tiles.x + self.tiles.w - 1 do
            mset(tx, ty, 0)
        end
    end
end

function Room:draw()
    self:draw_floor()
end

function Room:draw_floor()
    local rx = self.pixels.x
    local ry = self.pixels.y
    local rx2 = self.pixels.x + self.pixels.w
    local ry2 = self.pixels.y + self.pixels.h
    rectfill(rx, ry, rx2, ry2, self.floor_color)
end

return Room
