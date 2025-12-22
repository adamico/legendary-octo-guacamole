-- Enemy spawning system
local Entities = require("entities")

local Spawner = {}

Spawner.timer = 0
Spawner.spawned = false
Spawner.positions = {}
Spawner.indicator_sprite = 207

local function is_not_solid(tile)
    return tile and not fget(tile, SOLID_FLAG)
end

local function is_free_space(x, y)
    for _, pos in ipairs(Spawner.positions) do
        local dx = x - pos.x
        local dy = y - pos.y
        if dx * dx + dy * dy < 16 * 16 then
            return false
        end
    end
    return true
end

function Spawner.init_room(player, room_clip, num_enemies, min_dist, types)
    num_enemies = num_enemies or 5
    min_dist = min_dist or 80
    types = types or {"Skulker"}
    Spawner.timer = 60
    Spawner.spawned = false
    Spawner.positions = {}

    local attempts = 0
    while #Spawner.positions < num_enemies and attempts < 200 do
        attempts = attempts + 1
        local rx = (room_clip.x + rnd(room_clip.w - 1)) * GRID_SIZE
        local ry = (room_clip.y + rnd(room_clip.h - 1)) * GRID_SIZE

        local dx = rx - player.x
        local dy = ry - player.y
        if dx * dx + dy * dy > min_dist * min_dist then
            local tx, ty = flr((rx + 8) / 16), flr((ry + 8) / 16)
            local tile = mget(tx, ty)
            if is_not_solid(tile) and is_free_space(rx, ry) then
                local etype = types[flr(rnd(#types)) + 1]
                table.insert(Spawner.positions, {x = rx, y = ry, type = etype})
            end
        end
    end
end

function Spawner.update(world)
    if not Spawner.spawned then
        Spawner.timer -= 1
        if Spawner.timer <= 0 then
            for _, pos in ipairs(Spawner.positions) do
                Entities.spawn_enemy(world, pos.x, pos.y, pos.type)
            end
            Spawner.spawned = true
        end
    end
end

function Spawner.draw(room_pixels)
    if not Spawner.spawned then
        -- Blinking effect: toggle visibility every 15 frames, visible for 8
        if Spawner.timer % 15 < 8 then
            clip(room_pixels.x, room_pixels.y, room_pixels.w, room_pixels.h)
            for _, pos in ipairs(Spawner.positions) do
                spr(Spawner.indicator_sprite, pos.x, pos.y)
            end
            clip()
        end
    end
end

return Spawner
