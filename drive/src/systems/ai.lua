local AI = {}
local Entities = require("entities")

-- Enemy AI system: simple chase behavior
local function skulker_behavior(entity, player)
    local dx = player.x - entity.x
    local dy = player.y - entity.y
    local dist = sqrt(dx * dx + dy * dy)

    if dist > 0 then
        entity.vel_x = (dx / dist) * entity.speed
        entity.vel_y = (dy / dist) * entity.speed
        entity.dir_x = dx > 0 and 1 or -1
        entity.dir_y = dy > 0 and 1 or (dy < 0 and -1 or 0)
    end
end

local function shooter_behavior(entity, player)
    local dx = player.x - entity.x
    local dy = player.y - entity.y
    local dist = sqrt(dx * dx + dy * dy)

    -- Maintain distance (e.g. 100 pixels)
    local target_dist = 100
    if dist > target_dist + 20 then
        entity.vel_x = (dx / dist) * entity.speed
        entity.vel_y = (dy / dist) * entity.speed
    elseif dist < target_dist - 20 then
        entity.vel_x = -(dx / dist) * (entity.speed * 1.5)
        entity.vel_y = -(dy / dist) * (entity.speed * 1.5)
    else
        -- Slow down when at ideal distance
        entity.vel_x = entity.vel_x * 0.9
        entity.vel_y = entity.vel_y * 0.9
    end

    if dist > 0 then
        entity.dir_x = dx > 0 and 1 or -1
        entity.dir_y = dy > 0 and 1 or (dy < 0 and -1 or 0)
    end

    -- Shooting logic
    if entity.is_shooter and entity.shoot_timer then
        entity.shoot_timer = entity.shoot_timer - 1
        if entity.shoot_timer <= 0 then
            -- Shoot towards player
            if dist > 0 then
                Entities.spawn_enemy_projectile(world, entity.x, entity.y, dx / dist, dy / dist)
            end
            entity.shoot_timer = entity.shoot_delay
        end
    end
end

-- Enemy AI system: simple chase behavior
function AI.enemy_ai(entity)
    -- Find player
    local player = nil
    world.sys("player", function(p) player = p end)()

    if not player then return end

    if entity.enemy_type == "Skulker" then
        skulker_behavior(entity, player)
    elseif entity.enemy_type == "Shooter" then
        shooter_behavior(entity, player)
    end
end

return AI
