-- Enemy entity factory (Type Object pattern)
-- All enemy types are defined as pure data in GameConstants.Enemy
-- This factory simply instantiates entities from their type config
local GameConstants = require("constants")

local Enemy = {}

function Enemy.spawn(world, x, y, enemy_type)
    enemy_type = enemy_type or "Skulker"
    local config = GameConstants.Enemy[enemy_type]

    -- Build enemy entity from type config (instance data only)
    local enemy = {
        type = config.entity_type, -- From config
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
        flip_x = false
    }

    -- Copy type-specific properties if they exist
    if config.shoot_delay then
        enemy.shoot_timer = config.shoot_delay
        enemy.shoot_delay = config.shoot_delay
    end
    if config.is_shooter then
        enemy.is_shooter = true
    end

    -- Create entity with tags from config
    local ent = world.ent(config.tags, enemy)

    local Shadow = require("shadow")
    Shadow.spawn(world, ent)

    return ent
end

return Enemy
