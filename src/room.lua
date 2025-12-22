local Room = Class("Room")

function Room:initialize(x, y, w, h)
    self.pixels = {
        x = x * GRID_SIZE,
        y = y * GRID_SIZE,
        w = w * GRID_SIZE,
        h = h * GRID_SIZE
    }

    self.floor_color = 5
end

function Room:draw()
    local rx = self.pixels.x
    local ry = self.pixels.y
    local rx2 = self.pixels.x + self.pixels.w
    local ry2 = self.pixels.y + self.pixels.h
    rectfill(rx, ry, rx2, ry2, self.floor_color)
end

return Room
