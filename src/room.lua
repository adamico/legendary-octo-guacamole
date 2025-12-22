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

    -- Spawner state
    self.enemy_positions = {}
    self.spawn_timer = 60
    self.spawned = false
end

function Room:populate_enemies(player, num_enemies, min_dist, types)
    num_enemies = num_enemies or 5
    min_dist = min_dist or 80
    types = types or {"Skulker", "Shooter"}
    self.enemy_positions = {}

    local attempts = 0
    while #self.enemy_positions < num_enemies and attempts < 200 do
        attempts = attempts + 1
        -- Calculate random position within floor area
        local rx = (self.tiles.x + rnd(self.tiles.w - 1)) * GRID_SIZE
        local ry = (self.tiles.y + rnd(self.tiles.h - 1)) * GRID_SIZE

        -- Ensure distance from player
        local dx = rx - player.x
        local dy = ry - player.y
        if dx * dx + dy * dy > min_dist * min_dist then
            -- Ensure it's not on a solid tile and far from other enemies
            if self:is_free_space(rx, ry) then
                local etype = types[flr(rnd(#types)) + 1]
                table.insert(self.enemy_positions, {x = rx, y = ry, type = etype})
            end
        end
    end
end

function Room:is_free_space(x, y)
    -- Check against other enemy positions to prevent stacking
    for _, pos in ipairs(self.enemy_positions) do
        local dx = x - pos.x
        local dy = y - pos.y
        if dx * dx + dy * dy < 16 * 16 then
            return false
        end
    end
    return true
end

function Room:carve()
    local map_w = flr(SCREEN_WIDTH / GRID_SIZE)
    local map_h = flr(SCREEN_HEIGHT / GRID_SIZE)

    -- Fill screen with walls
    for ty = 0, map_h - 1 do
        for tx = 0, map_w - 1 do
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
