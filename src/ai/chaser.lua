local wanderer = require("ai/wanderer")

local function chaser_behavior(entity, player)
    local dx = player.x - entity.x
    local dy = player.y - entity.y
    local dist = sqrt(dx * dx + dy * dy)
    local vision_range = entity.vision_range

    -- If no vision_range defined, always chase (original behavior)
    if vision_range and dist > vision_range then
        -- Out of range: wander
        wanderer.update(entity)
    else
        -- In range or no vision limit: chase
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
