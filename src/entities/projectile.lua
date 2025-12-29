-- Projectile entity factory (Type Object pattern)
-- All projectile types are defined as pure data in GameConstants.Projectile
-- This factory simply instantiates entities from their type config
local GameConstants = require("src/game/game_config")
local EntityUtils = require("src/utils/entity_utils")
local HitboxUtils = require("src/utils/hitbox_utils")

local Projectile = {}

-- Unified spawn function using Type Object pattern
-- @param world - ECS world
-- @param x, y - spawn position
-- @param dx, dy - direction vector (normalized)
-- @param projectile_type - type key in GameConstants.Projectile (default: "Egg")
-- @param instance_data - optional table with instance-specific overrides
function Projectile.spawn(world, x, y, dx, dy, projectile_type, instance_data)
    projectile_type = projectile_type or "Egg"
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

    -- 2d. Initialize Z-axis data (simulated height)
    projectile.z = instance_data.z or projectile.z or 8 -- Default start height
    projectile.age = 0
    projectile.max_age = instance_data.lifetime or 60
    projectile.vel_z = 0 -- Start with no vertical velocity (horizontal flight)

    -- Calculate gravity to drop from z to 0 in the last 25% of lifetime
    -- T_drop = max_age * 0.25
    -- 0 = z0 + 0*t + 0.5*g*t^2  => g = -2*z0 / t^2
    local drop_duration = projectile.max_age * 0.25
    if drop_duration < 1 then drop_duration = 1 end -- Prevent division by zero
    projectile.gravity_z = (-2 * projectile.z) / (drop_duration * drop_duration)

    -- 3. Static table references
    projectile.hitbox = config.hitbox
    projectile.animations = config.animations
    projectile.palette_swaps = config.palette_swaps
    projectile.sprite_index_offsets = config.sprite_index_offsets
    projectile.shadow_offsets_y = config.shadow_offsets_y
    projectile.shadow_offsets_x = config.shadow_offsets_x
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
    local shooter_hitbox = HitboxUtils.get_hitbox(shooter)
    local projectile_config = GameConstants.Projectile[projectile_type or "Egg"]

    local spawn_x = shooter_hitbox.x + (shooter_hitbox.w / 2) - (projectile_config.width / 2)
    local spawn_y = shooter_hitbox.y + (shooter_hitbox.h / 2) - (projectile_config.height / 2)

    return Projectile.spawn(world, spawn_x, spawn_y, dx, dy, projectile_type, instance_data)
end

return Projectile
