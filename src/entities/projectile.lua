-- Projectile entity factory (Type Object pattern)
-- All projectile types are defined as pure data in GameConstants.Projectile
-- This factory simply instantiates entities from their type config
local GameConstants = require("src/game/game_config")
local EntityUtils = require("src/utils/entity_utils")

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
    if not config then
        Log.error("Attempted to spawn unknown projectile type: "..tostring(projectile_type))
        return nil
    end

    local direction = EntityUtils.get_direction_name(dx, dy)

    -- 1. Base identity and physics state
    local projectile = {
        type = config.entity_type or "Projectile",
        projectile_type = projectile_type,
        x = x,
        y = y,
        direction = direction,
        dir_x = dx,
        dir_y = dy,
        sub_x = 0,
        sub_y = 0,
    }
    -- 2. Bulk copy all non-table values from config (stats, bounds, offsets)
    for k, v in pairs(config) do
        if type(v) ~= "table" then
            projectile[k] = v
        end
    end

    -- 2b. Apply instance-specific overrides EARLY to ensure derived stats (velocity) use correct values
    for k, v in pairs(instance_data) do
        projectile[k] = v
    end

    -- 2c. Recalculate velocity with final speed
    if projectile.speed then
        projectile.vel_x = dx * projectile.speed
        projectile.vel_y = dy * projectile.speed
    end

    -- 3. Static table references
    projectile.hitbox = config.hitbox
    projectile.animations = config.animations
    projectile.palette_swaps = config.palette_swaps
    projectile.sprite_index_offsets = config.sprite_index_offsets
    projectile.shadow_offsets = config.shadow_offsets
    projectile.shadow_widths = config.shadow_widths
    projectile.shadow_heights = config.shadow_heights

    -- 4. Contextual initialization
    if projectile.sprite_index_offsets and direction then
        projectile.sprite_index = projectile.sprite_index_offsets[direction]
    end

    -- 5. Apply instance-specific overrides
    for k, v in pairs(instance_data) do
        projectile[k] = v
    end

    -- 6.Create entity with tags from config
    return EntityUtils.spawn_entity(world, config.tags, projectile)
end

-- Spawn projectile centered on shooter's hitbox
function Projectile.spawn_centered(world, shooter, dx, dy, projectile_type, instance_data)
    local HitboxUtils = require("src/utils/hitbox_utils")
    local shooter_hb = HitboxUtils.get_hitbox(shooter)
    local proj_config = GameConstants.Projectile[projectile_type or "Laser"]

    local spawn_x = shooter_hb.x + (shooter_hb.w / 2) - (proj_config.width / 2)
    local spawn_y = shooter_hb.y + (shooter_hb.h / 2) - (proj_config.height / 2)

    return Projectile.spawn(world, spawn_x, spawn_y, dx, dy, projectile_type, instance_data)
end

return Projectile
