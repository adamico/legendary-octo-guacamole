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

    -- Parse tags from comma-separated config string into a lookup table
    local tag_set = {}
    for tag in all(split(config.tags or "", ",")) do
        tag_set[tag] = true
    end

    -- Build entity with all components
    local entity = {
        -- Type identifier
        type = {value = config.entity_type or "Enemy"},
        enemy_type = {value = enemy_type},

        -- Transform
        position = {x = x, y = y},
        size = {width = config.width or 16, height = config.height or 16},

        -- Movement
        acceleration = {
            accel = 0,
            friction = 0.5,
            max_speed = config.max_speed or 0.5,
        },
        velocity = {
            vel_x = 0,
            vel_y = 0,
            sub_x = 0,
            sub_y = 0,
        },
        direction = {
            dir_x = 0,
            dir_y = 1, -- Default facing down
        },

        -- Collision
        collidable = {
            hitboxes = config.hitboxes or {
                w = config.hitbox_width or 12,
                h = config.hitbox_height or 10,
                ox = config.hitbox_offset_x or 2,
                oy = config.hitbox_offset_y or 3,
            },
            map_collidable = tag_set.map_collidable or false,
        },

        -- Health
        health = {
            hp = config.hp or 10,
            max_hp = config.hp or 10,
            overflow_hp = 0,
            overflow_banking = false,
        },

        -- Timers
        timers = {
            shoot_cooldown = 0,
            invuln_timer = 0,
            hp_drain_timer = 0,
        },

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

        -- Visuals: Shadow
        shadow = {
            shadow_offset_x = config.shadow_offset_x or 0,
            shadow_offset_y = config.shadow_offset_y or 0,
            shadow_width = config.shadow_width or 15,
            shadow_height = config.shadow_height or 3,
            shadow_offsets_x = config.shadow_offsets_x,
            shadow_offsets_y = config.shadow_offsets_y,
            shadow_widths = config.shadow_widths,
            shadow_heights = config.shadow_heights,
        },

        -- Visuals: Drawable
        drawable = {
            outline_color = config.outline_color or 1,
            sort_offset_y = 0,
            sprite_index = EntityUtils.get_sprite_index(config, "down"),
            flip_x = false,
            flip_y = false,
        },

        -- Visuals: Animation
        animatable = {
            animations = config.animations,
            sprite_index_offsets = config.sprite_index_offsets,
        },
    }

    -- Copy all parsed tags from config into entity
    for tag, _ in pairs(tag_set) do
        entity[tag] = true
    end

    -- All enemies can display emotions
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
