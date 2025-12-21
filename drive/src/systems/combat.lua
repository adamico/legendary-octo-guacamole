-- Combat systems: shooting, health management, regen
local Entities = require("entities")
local GameConstants = require("constants")

local Combat = {}

-- Invulnerability timer system: counts down invuln frames
function Combat.invulnerability_tick(entity)
    if entity.invuln_timer and entity.invuln_timer > 0 then
        entity.invuln_timer = entity.invuln_timer - 1
    end
end

-- Helper: convert shoot direction to facing direction name
local function direction_from_shoot(sx, sy)
    if sx > 0 then
        return "right"
    elseif sx < 0 then
        return "left"
    elseif sy > 0 then
        return "down"
    elseif sy < 0 then
        return "up"
    end
    return nil
end

-- Shoot input system: reads buttons, sets shoot direction on entity
function Combat.shoot_input(entity)
    -- Read directional shooting buttons
    local sx = 0
    local sy = 0
    if btn(GameConstants.controls.shoot_left) then sx = -1 end
    if btn(GameConstants.controls.shoot_right) then sx = 1 end
    if btn(GameConstants.controls.shoot_up) then sy = -1 end
    if btn(GameConstants.controls.shoot_down) then sy = 1 end

    entity.shoot_dir_x = sx
    entity.shoot_dir_y = sy
end

-- Projectile fire system: checks conditions, spawns projectile, handles FSM
function Combat.projectile_fire(entity)
    -- Reduce cooldown
    if entity.shoot_cooldown then
        entity.shoot_cooldown = max(0, entity.shoot_cooldown - 1)
    end

    local sx = entity.shoot_dir_x or 0
    local sy = entity.shoot_dir_y or 0

    -- Fire if cooldown ready and HP sufficient
    local cooldown_ready = (entity.shoot_cooldown or 0) == 0
    local wants_to_shoot = sx ~= 0 or sy ~= 0
    local has_enough_hp = entity.hp > entity.shot_cost

    if wants_to_shoot and has_enough_hp and cooldown_ready then
        -- Update facing direction
        local dir = direction_from_shoot(sx, sy)
        if dir and entity.fsm then
            entity.current_direction = dir
            -- Trigger or extend attack animation
            if not entity.fsm:attack() and entity.fsm:is("attacking") then
                entity.anim_timer = 0 -- Extend animation
            end
        end

        -- Consume HP and spawn projectile
        entity.hp -= entity.shot_cost
        entity.time_since_shot = 0
        Entities.spawn_projectile(
            world, entity.x + entity.width / 2 - 2,
            entity.y + entity.height / 2 - 2, sx, sy,
            entity.recovery_percent, entity.shot_cost
        )
        entity.shoot_cooldown = 15
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
        -- If entity has an FSM, let the FSM handle the death sequence
        if entity.fsm then
            if not entity.fsm:is("death") then
                entity.fsm:die()
            end
        else
            -- No FSM, delete immediately
            local handler = Combat.DeathHandlers[entity.type] or Combat.DeathHandlers.default
            handler(entity)
        end
    end
end

return Combat
