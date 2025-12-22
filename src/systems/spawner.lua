-- Enemy spawning system
local Entities = require("entities")

local Spawner = {}

Spawner.indicator_sprite = 207

function Spawner.update(world, room)
    if not room or room.spawned then return end

    room.spawn_timer -= 1
    if room.spawn_timer <= 0 then
        for _, pos in ipairs(room.enemy_positions) do
            Entities.spawn_enemy(world, pos.x, pos.y, pos.type)
        end
        room.spawned = true
    end
end

function Spawner.draw(room)
    if not room or room.spawned then return end

    -- Blinking effect: toggle visibility every 15 frames, visible for 8
    if room.spawn_timer % 15 < 8 then
        clip(room.pixels.x, room.pixels.y, room.pixels.w, room.pixels.h)
        for _, pos in ipairs(room.enemy_positions) do
            spr(Spawner.indicator_sprite, pos.x, pos.y)
        end
        clip()
    end
end

return Spawner
