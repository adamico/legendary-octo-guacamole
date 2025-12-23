-- Projectile entity factory (Type Object pattern)
-- All projectile types are defined as pure data in GameConstants.Projectile
-- This factory simply instantiates entities from their type config
local GameConstants = require("constants")
local Utils = require("utils")

local Projectile = {}

-- Unified spawn function using Type Object pattern
-- @param world - ECS world
-- @param x, y - spawn position
-- @param dx, dy - direction vector (normalized)
-- @param projectile_type - type key in GameConstants.Projectile (default: "Laser")
-- @param instance_data - optional table with instance-specific overrides
function Projectile.spawn(world, x, y, dx, dy, projectile_type, instance_data)
    projectile_type = projectile_type or "Laser"
    instance_data = instance_data or {}

    local config = GameConstants.Projectile[projectile_type]
    local direction = Utils.get_direction_name(dx, dy)

    -- Build projectile entity from type config
    local projectile = {
        type = config.entity_type,
        projectile_type = projectile_type,
        x = x,
        y = y,
        width = config.width,
        height = config.height,
        hitbox = config.hitbox,
        hitbox_width = config.hitbox_width,
        hitbox_height = config.hitbox_height,
        hitbox_offset_x = config.hitbox_offset_x,
        hitbox_offset_y = config.hitbox_offset_y,
        direction = direction,
        dir_x = dx,
        dir_y = dy,
        vel_x = dx * config.speed,
        vel_y = dy * config.speed,
        sub_x = 0,
        sub_y = 0,
        damage = config.damage,
        owner = config.owner,
        animations = config.animations,
        palette_swaps = config.palette_swaps,
        sprite_index = config.sprite_index_offsets[direction],
        sprite_offset_y = config.sprite_offset_y or 0,
        shadow_offset = config.shadow_offset or 0,
        shadow_offsets = config.shadow_offsets,
        shadow_width = config.shadow_width,
        shadow_height = config.shadow_height,
        shadow_widths = config.shadow_widths,
        shadow_heights = config.shadow_heights,
    }

    -- Apply instance-specific overrides
    for k, v in pairs(instance_data) do
        projectile[k] = v
    end

    -- Create entity with tags from config (shadow auto-spawned if tagged)
    return Utils.spawn_entity(world, config.tags, projectile)
end

return Projectile
