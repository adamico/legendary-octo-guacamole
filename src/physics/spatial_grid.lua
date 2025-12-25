local SpatialGrid = Class("SpatialGrid")

function SpatialGrid:initialize(cell_size)
    self.cell_size = cell_size or SPATIAL_GRID_CELL_SIZE
    self.cells = {}
end

function SpatialGrid:add(entity, get_hitbox_fn)
    local hb = get_hitbox_fn(entity)
    local x1 = flr(hb.x / self.cell_size)
    local y1 = flr(hb.y / self.cell_size)
    local x2 = flr((hb.x + hb.w) / self.cell_size)
    local y2 = flr((hb.y + hb.h) / self.cell_size)

    for cx = x1, x2 do
        for cy = y1, y2 do
            local key = cx..","..cy
            if not self.cells[key] then
                self.cells[key] = {}
            end
            table.insert(self.cells[key], entity)
        end
    end
end

function SpatialGrid:get_nearby(entity, get_hitbox_fn)
    local hb = get_hitbox_fn(entity)
    local nearby = {}
    local seen = {}

    local x1 = flr(hb.x / self.cell_size)
    local y1 = flr(hb.y / self.cell_size)
    local x2 = flr((hb.x + hb.w) / self.cell_size)
    local y2 = flr((hb.y + hb.h) / self.cell_size)

    for cx = x1, x2 do
        for cy = y1, y2 do
            local cell = self.cells[cx..","..cy]
            if cell then
                for _, other in ipairs(cell) do
                    if not seen[other] and other ~= entity then
                        seen[other] = true
                        table.insert(nearby, other)
                    end
                end
            end
        end
    end

    return nearby
end

return SpatialGrid
