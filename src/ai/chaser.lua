local wanderer = require("wanderer")
local Emotions = require("emotions")

local function chaser_behavior(entity, player)
    local dx = player.x - entity.x
    local dy = player.y - entity.y
    local dist = sqrt(dx * dx + dy * dy)
    local vision_range = entity.vision_range

    -- Track previous state to detect transitions
    local was_chasing = entity.ai_state == "chasing"
    local was_wandering = entity.ai_state == "wandering"

    -- If no vision_range defined, always chase (original behavior)
    if vision_range and dist > vision_range then
        -- Out of range: wander
        entity.ai_state = "wandering"

        -- Transition: was chasing, now wandering -> confused
        if was_chasing then
            Emotions.set(entity, "confused")
        end

        wanderer.update(entity)
    else
        -- In range or no vision limit: chase
        local spotted = (entity.ai_state == nil or was_wandering)
        entity.ai_state = "chasing"

        -- Transition: was wandering or first encounter -> alert
        if spotted then
            Emotions.set(entity, "alert")
        end

        wanderer.reset(entity)

        if dist > 0 then
            entity.vel_x = (dx / dist) * entity.speed
            entity.vel_y = (dy / dist) * entity.speed
            entity.dir_x = sgn(dx)
            entity.dir_y = sgn(dy)
        end
    end
end

return chaser_behavior
