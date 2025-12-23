-- Projectile entity factory (Type Object pattern)
-- All projectile types are defined as pure data in GameConstants.Projectile
-- This factory simply instantiates entities from their type config
local GameConstants = require("constants")

local Projectile = {}

-- Helper to determine direction name from velocity
local function get_direction(dx, dy)
    if dx > 0 then
        return "right"
    elseif dx < 0 then
        return "left"
    elseif dy < 0 then
        return "up"
    else
        return "down"
    end
end

-- Unified spawn function using Type Object pattern
-- @param world - ECS world
-- @param x, y - spawn position
-- @param dx, dy - direction vector (normalized)
-- @param projectile_type - type key in GameConstants.Projectile (default: "Laser")
-- @param instance_data - optional table with instance-specific overrides (recovery_percent, shot_cost)
function Projectile.spawn(world, x, y, dx, dy, projectile_type, instance_data)
    projectile_type = projectile_type or "Laser"
    instance_data = instance_data or {}

    local config = GameConstants.Projectile[projectile_type]
    local direction = get_direction(dx, dy)

    -- Build projectile entity from type config
    local projectile = {
        type = config.entity_type,
        projectile_type = projectile_type,
        x = x,
        y = y,
        width = config.width,
        height = config.height,
        -- Direction-based hitbox (looked up by get_hitbox using direction)
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

    -- Apply instance-specific overrides (for player projectiles)
    if instance_data.recovery_percent then
        projectile.recovery_percent = instance_data.recovery_percent
    end
    if instance_data.shot_cost then
        projectile.shot_cost = instance_data.shot_cost
    end

    -- Create entity with tags from config
    local ent = world.ent(config.tags, projectile)

    local Shadow = require("shadow")
    Shadow.spawn(world, ent)

    return ent
end

return Projectile
