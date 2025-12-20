-- Enemy AI systems
local AI = {}

-- Enemy AI system: simple chase behavior
function AI.enemy_ai(entity)
    -- Find player
    local player = nil
    world.sys("player", function(p) player = p end)()

    if not player then return end

    -- Calculate direction to player
    local dx = player.x - entity.x
    local dy = player.y - entity.y
    local dist = sqrt(dx * dx + dy * dy)

    if dist > 0 then
        -- Normalize and apply speed
        entity.vel_x = (dx / dist) * entity.speed
        entity.vel_y = (dy / dist) * entity.speed

        -- Store direction for sprite updates
        entity.dir_x = dx > 0 and 1 or -1
        entity.dir_y = dy > 0 and 1 or (dy < 0 and -1 or 0)
    end
end

return AI
