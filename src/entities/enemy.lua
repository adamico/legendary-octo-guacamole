-- Enemy entity factory (Type Object pattern)
-- All enemy types are defined as pure data in GameConstants.Enemy
-- This factory simply instantiates entities from their type config
local GameConstants = require("constants")
local Utils = require("utils")

local Enemy = {}

-- Unified spawn function using Type Object pattern
-- @param world - ECS world
-- @param x, y - spawn position
-- @param enemy_type - type key in GameConstants.Enemy (default: "Skulker")
-- @param instance_data - optional table with instance-specific overrides
function Enemy.spawn(world, x, y, enemy_type, instance_data)
    enemy_type = enemy_type or "Skulker"
    instance_data = instance_data or {}

    local config = GameConstants.Enemy[enemy_type]

    -- Build enemy entity from type config
    local enemy = {
        type = config.entity_type,
        enemy_type = enemy_type,
        x = x,
        y = y,
        width = config.width,
        height = config.height,
        hitbox_width = config.hitbox_width,
        hitbox_height = config.hitbox_height,
        hitbox_offset_x = config.hitbox_offset_x,
        hitbox_offset_y = config.hitbox_offset_y,
        shadow_offset = config.shadow_offset or 0,
        shadow_offsets = config.shadow_offsets,
        shadow_width = config.shadow_width,
        shadow_height = config.shadow_height,
        shadow_widths = config.shadow_widths,
        shadow_heights = config.shadow_heights,
        hp = config.hp,
        max_hp = config.hp,
        speed = config.speed,
        contact_damage = config.contact_damage,
        vel_x = 0,
        vel_y = 0,
        sub_x = 0,
        sub_y = 0,
        dir_x = 0,
        dir_y = 1,
        sprite_index = config.sprite_index_offsets.down,
        flip_x = false,
        -- Type-specific properties from config
        shoot_timer = config.shoot_delay,
        shoot_delay = config.shoot_delay,
        is_shooter = config.is_shooter,
        -- Dasher-specific properties
        vision_range = config.vision_range,
        windup_duration = config.windup_duration,
        stun_duration = config.stun_duration,
        dash_speed_multiplier = config.dash_speed_multiplier,
        sprite_shell = config.sprite_shell,
        -- Dasher state (initialized at spawn)
        dasher_state = config.vision_range and "patrol" or nil, -- patrol/windup/dash/stun
        dasher_timer = 0,
        patrol_dir_x = 0,
        patrol_dir_y = 1, -- Start moving down
        dash_target_dx = 0,
        dash_target_dy = 0,
    }

    -- Apply instance-specific overrides
    for k, v in pairs(instance_data) do
        enemy[k] = v
    end

    -- Create entity with tags from config (shadow auto-spawned if tagged)
    return Utils.spawn_entity(world, config.tags, enemy)
end

return Enemy
