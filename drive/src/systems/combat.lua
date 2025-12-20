-- Combat systems: shooting, health management, regen
local Entities = require("entities")
local GameConstants = require("constants")

local Combat = {}

-- Shooter system: handle projectile firing
function Combat.shooter(entity)
    -- Reduce cooldown
    if entity.shoot_cooldown then
        entity.shoot_cooldown = max(0, entity.shoot_cooldown - 1)
    end

    -- Read directional shooting buttons (8-11)
    local sx = 0
    local sy = 0
    if btn(GameConstants.controls.shoot_left) then sx = -1 end
    if btn(GameConstants.controls.shoot_right) then sx = 1 end
    if btn(GameConstants.controls.shoot_up) then sy = -1 end
    if btn(GameConstants.controls.shoot_down) then sy = 1 end

    -- Fire if cooldown ready and HP sufficient
    local cooldown_ready = not entity.shoot_cooldown or entity.shoot_cooldown == 0
    if (sx ~= 0 or sy ~= 0) and entity.hp > entity.shot_cost and cooldown_ready then
        -- Fire shot
        entity.hp -= entity.shot_cost
        entity.time_since_shot = 0 -- Reset regen timer
        Entities.spawn_projectile(
            world, entity.x + entity.width / 2 - 2,
            entity.y + entity.height / 2 - 2, sx, sy,
            entity.recovery_percent, entity.shot_cost
        )
        entity.shoot_cooldown = 15 -- Adjust as needed
    end
end

-- Health regen system: passive HP recovery (60 FPS)
function Combat.health_regen(entity)
    if not entity.regen_rate or entity.regen_rate <= 0 then return end

    -- Track time since last shot
    entity.time_since_shot = (entity.time_since_shot or 0) + (1 / 60)

    -- Only regen after delay
    if entity.time_since_shot >= entity.regen_delay then
        entity.hp = entity.hp + (entity.regen_rate / 60)

        -- Bank overflow HP
        if entity.hp > entity.max_hp then
            entity.overflow_hp = (entity.overflow_hp or 0) + (entity.hp - entity.max_hp)
            entity.hp = entity.max_hp
        end
    end
end

-- Death Handlers Registry
Combat.DeathHandlers = {}

-- Player death handler
Combat.DeathHandlers["Player"] = function(entity)
    Log.trace("Player died!")
    -- For now just trace, could gotoState("GameOver") later
    -- entity.hp = entity.max_hp  -- Uncomment to respawn
end

-- Default death handler for other entities
Combat.DeathHandlers.default = function(entity)
    -- Visual/audio feedback for death
    local Effects = require("effects")
    Effects.death_explosion(entity, "explosion")

    world.del(entity)
end

-- Health manager: check for death
function Combat.health_manager(entity)
    if entity.hp and entity.hp <= 0 then
        local handler = Combat.DeathHandlers[entity.type] or Combat.DeathHandlers.default
        handler(entity)
    end
end

return Combat
