local Entities = require("entities")
local wanderer = require("wanderer")
local Emotions = require("emotions")

local SHOOTER_VISION_RANGE = 200
local SHOOTER_TARGET_DIST = 100
local SHOOTER_TARGET_DIST_VARIANCE = 20

local function shooter_behavior(entity, player)
    local dx = player.x - entity.x
    local dy = player.y - entity.y
    local dist = sqrt(dx * dx + dy * dy)
    local vision_range = entity.vision_range or SHOOTER_VISION_RANGE

    -- Track previous state to detect transitions
    local was_engaging = entity.ai_state == "engaging"
    local was_wandering = entity.ai_state == "wandering"

    if dist <= vision_range then
        -- Player spotted: reset wandering state and engage
        local is_first_contact = entity.ai_state == nil
        entity.ai_state = "engaging"

        -- Transition: was wandering, now engaging -> alert
        if was_wandering or is_first_contact then
            Emotions.set(entity, "alert")
        end

        wanderer.reset(entity)

        -- Maintain distance
        if dist > SHOOTER_TARGET_DIST + SHOOTER_TARGET_DIST_VARIANCE then
            entity.vel_x = (dx / dist) * entity.speed
            entity.vel_y = (dy / dist) * entity.speed
        elseif dist < SHOOTER_TARGET_DIST - SHOOTER_TARGET_DIST_VARIANCE then
            entity.vel_x = -(dx / dist) * (entity.speed * 1.5)
            entity.vel_y = -(dy / dist) * (entity.speed * 1.5)
        else
            -- Slow down when at ideal distance
            entity.vel_x = entity.vel_x * 0.9
            entity.vel_y = entity.vel_y * 0.9
        end

        if dist > 0 then
            entity.dir_x = sgn(dx)
            entity.dir_y = sgn(dy)
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
    else
        -- Out of vision range: wander randomly
        entity.ai_state = "wandering"

        -- Transition: was engaging, now wandering -> confused
        if was_engaging then
            Emotions.set(entity, "confused")
        end

        wanderer.update(entity)
    end
end

return shooter_behavior
