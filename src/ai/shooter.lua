local machine = require("lua-state-machine/statemachine")
local Entities = require("entities")
local wanderer = require("wanderer")
local Emotions = require("emotions")

local SHOOTER_VISION_RANGE = 200
local SHOOTER_TARGET_DIST = 100
local SHOOTER_TARGET_DIST_VARIANCE = 20
local PUZZLED_DURATION = 60 -- frames to stay puzzled before wandering

-- Initialize Shooter FSM on entity
local function init_shooter_fsm(entity)
    entity.shooter_fsm = machine.create({
        initial = "wandering",
        events = {
            {name = "spot",   from = "wandering", to = "engaging"},
            {name = "spot",   from = "puzzled",   to = "engaging"}, -- Can re-spot during puzzled
            {name = "lose",   from = "engaging",  to = "puzzled"},
            {name = "wander", from = "puzzled",   to = "wandering"},
        },
        callbacks = {
            onenterengaging = function()
                Emotions.set(entity, "alert")
                wanderer.reset(entity)
            end,
            onenterpuzzled = function()
                Emotions.set(entity, "confused")
                entity.puzzled_timer = PUZZLED_DURATION
                entity.vel_x = 0
                entity.vel_y = 0
            end,
            onenterwandering = function()
                -- No emotion on entering wandering, puzzled already showed "?"
            end,
        }
    })
end

local function shooter_behavior(entity, player)
    -- Initialize FSM if needed
    if not entity.shooter_fsm then
        init_shooter_fsm(entity)
    end

    local fsm = entity.shooter_fsm
    local dx = player.x - entity.x
    local dy = player.y - entity.y
    local dist = sqrt(dx * dx + dy * dy)
    local vision_range = entity.vision_range or SHOOTER_VISION_RANGE

    if fsm:is("wandering") then
        if dist <= vision_range then
            fsm:spot()
        else
            wanderer.update(entity)
        end
    elseif fsm:is("engaging") then
        if dist > vision_range then
            fsm:lose()
        else
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
        end
    elseif fsm:is("puzzled") then
        -- Stand still, wait for timer
        entity.vel_x = 0
        entity.vel_y = 0

        -- Can re-spot player during puzzled state
        if dist <= vision_range then
            fsm:spot()
        else
            entity.puzzled_timer = entity.puzzled_timer - 1
            if entity.puzzled_timer <= 0 then
                fsm:wander()
            end
        end
    end
end

return shooter_behavior
