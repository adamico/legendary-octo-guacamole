-- Enemy entity factory (picobloc version)
-- All enemy types are defined as pure data in GameConstants.Enemy
local GameConstants = require("src/game/game_config")
local EntityUtils = require("src/utils/entity_utils")

local Enemy = {}

-- Unified spawn function using Type Object pattern
--- @param world ECSWorld - picobloc World
--- @param x number - spawn x position
--- @param y number - spawn y position
--- @param enemy_type? string - type key in GameConstants.Enemy (default: "Skulker")
--- @param instance_data? table - optional table with instance-specific overrides
function Enemy.spawn(world, x, y, enemy_type, instance_data)
    enemy_type = enemy_type or "Skulker"
    instance_data = instance_data or {}

    local config = GameConstants.Enemy[enemy_type]
    if not config then
        Log.error("Attempted to spawn unknown enemy type: "..tostring(enemy_type))
        return nil
    end

    -- Parse tags from config
    local tag_set = EntityUtils.parse_tags(config.tags)

    -- Build entity with centralized component builders
    local entity = {
        -- Type identifier
        type = {value = config.entity_type or "Enemy"},
        enemy_type = {value = enemy_type},

        -- Transform
        position = {x = x, y = y},
        size = EntityUtils.build_size(config),

        -- Movement
        acceleration = EntityUtils.build_acceleration(config),
        velocity = EntityUtils.build_velocity(),
        direction = EntityUtils.build_direction(0, 1), -- Default facing down

        -- Collision
        collidable = EntityUtils.build_collidable(config, {map_collidable = true}),

        -- Health
        health = EntityUtils.build_health(config),

        -- Timers
        timers = EntityUtils.build_timers(),

        -- AI
        enemy_ai = {
            fsm = nil, -- FSM initialized by AI system
            vision_range = config.vision_range or 120,
            wander_radius = config.wander_radius or 40,
            wander_speed_mult = config.wander_speed_mult or 0.6,
            wander_pause_min = config.wander_pause_min or 20,
            wander_pause_max = config.wander_pause_max or 60,
        },

        -- Combat
        contact_damage = {
            damage = config.contact_damage or 10,
        },

        -- Drops
        drop = {
            drop_chance = config.drop_chance or 1.0,
            loot_rolls = config.loot_rolls or 1,
            use_diverse_loot = config.use_diverse_loot or false,
            xp_value = config.xp_value or 10,
        },

        -- Visuals
        shadow = EntityUtils.build_shadow(config),
        drawable = EntityUtils.build_drawable(config, "down"),
        animatable = EntityUtils.build_animatable(config),
    }

    -- Apply parsed tags and emotional flag
    EntityUtils.apply_tags(entity, tag_set)
    entity.emotional = true

    -- Add shooter component if tagged (requires full component data)
    if tag_set.shooter then
        entity.shooter = {
            shoot_cooldown = 0,
            shot_speed = config.shot_speed or 1.5,
            shoot_cooldown_duration = config.shoot_delay or 60,
            health_as_ammo = false,
            projectile_type = "EnemyBullet",
            max_hp_to_shot_cost_ratio = 0,
            max_hp_to_damage_ratio = 0,
            time_since_shot = 0,
            fire_rate = config.shoot_delay or 60,
            impact_damage = config.damage or 10,
            knockback = 0,
            range = config.range or 200,
            drain_damage = 0,
            drain_heal = 0,
            recovery_percent = 0,
            hatch_time = 0,
            projectile_origin_x = 0,
            projectile_origin_y = 0,
            projectile_origin_z = 0,
        }
    end

    -- Add dasher component if this is a Dasher
    if enemy_type == "Dasher" then
        entity.dasher = {
            windup_duration = config.windup_duration or 60,
            stun_duration = config.stun_duration or 120,
            dash_speed_multiplier = config.dash_speed_multiplier or 10,
        }
    end

    local id = world:add_entity(entity)

    -- Apply instance overrides (not yet supported in picobloc)
    if next(instance_data) then
        Log.warn("Instance overrides not yet supported in picobloc enemy factory")
    end

    return id
end

return Enemy
