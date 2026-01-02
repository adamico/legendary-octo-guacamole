-- Projectile entity factory (picobloc version)
-- All projectile types are defined as pure data in GameConstants.Projectile
local GameConstants = require("src/game/game_config")
local EntityUtils = require("src/utils/entity_utils")

local Projectile = {}

--- Unified spawn function using Type Object pattern
--- @param world ECSWorld - picobloc World
--- @param x number - spawn x position
--- @param y number - spawn y position
--- @param dx number - direction x component (normalized)
--- @param dy number - direction y component (normalized)
--- @param projectile_type string - type key in GameConstants.Projectile (default: "Egg")
--- @param instance_data? table - optional table with instance-specific overrides
function Projectile.spawn(world, x, y, dx, dy, projectile_type, instance_data)
    projectile_type = projectile_type or "Egg"
    instance_data = instance_data or {}

    local config = GameConstants.Projectile[projectile_type]
    if not config then
        Log.error("Attempted to spawn unknown projectile type: "..tostring(projectile_type))
        return nil
    end

    -- Parse tags from config
    local tag_set = EntityUtils.parse_tags(config.tags)

    local direction = EntityUtils.get_direction_name(dx, dy)
    local speed = instance_data.speed or config.speed

    -- Calculate initial Z and gravity
    -- REVIEW: can this be refactored with timers?
    local initial_z = instance_data.z or config.z
    local max_age = instance_data.lifetime or 60
    local drop_duration = max_age * 0.25
    if drop_duration < 1 then drop_duration = 1 end
    local gravity_z = (-2 * initial_z) / (drop_duration * drop_duration)

    -- Build entity with centralized component builders
    local entity = {
        -- Type identifier
        type = {value = config.entity_type or "Projectile"},
        projectile_type = {value = projectile_type},

        -- Owner
        projectile_owner = {
            owner = config.owner or "player",
        },

        -- Z-axis physics (Custom override for position)
        position = {x = x, y = y, z = initial_z},
        size = EntityUtils.build_size(config),
        direction = EntityUtils.build_direction(dx, dy),

        -- Movement
        velocity = EntityUtils.build_velocity(dx * speed, dy * speed, 0),
        acceleration = EntityUtils.build_acceleration(config, {
            accel = 0,
            friction = 0,
            gravity_z = gravity_z
        }),

        lifetime = {
            age = 0,
            max_age = max_age,
        },

        -- Collision
        collidable = EntityUtils.build_collidable(config, {
            map_collidable = true,
            w = 8,
            h = 8,
            ox = 4,
            oy = 4
        }),

        -- Combat
        projectile_combat = {
            damage = instance_data.damage or config.damage,
            knockback = instance_data.knockback or config.knockback,
        },

        -- Visuals
        shadow = EntityUtils.build_shadow(config),
        drawable = EntityUtils.build_drawable(config, direction),
        animatable = EntityUtils.build_animatable(config),
    }

    -- Apply parsed tags
    EntityUtils.apply_tags(entity, tag_set)

    -- Force max_speed to 0 (physics quirk for projectiles)
    entity.acceleration.max_speed = 0

    local id = world:add_entity(entity)
    return id
end

-- Spawn projectile from shooter's configured origin point
function Projectile.spawn_from_origin(world, shooter, dx, dy, projectile_type, instance_data)
    local projectile_config = GameConstants.Projectile[projectile_type or "Egg"]

    local origin_x, origin_y
    if shooter.projectile_origin_x then
        origin_x = shooter.x + shooter.projectile_origin_x
        origin_y = shooter.y + (shooter.projectile_origin_y or 0)
    else
        -- Default to entity center
        local width = shooter.width or 16
        local height = shooter.height or 16
        origin_x = shooter.x + width / 2
        origin_y = shooter.y + height / 2
    end

    -- Offset by half projectile size to center it on origin
    local spawn_x = origin_x - (projectile_config.width / 2)
    local spawn_y = origin_y - (projectile_config.height / 2)

    -- Z elevation
    local projectile_z = shooter.projectile_origin_z or shooter.z or 0

    instance_data = instance_data or {}
    instance_data.z = projectile_z

    -- Flag vertical shots
    local is_vertical = (abs(dy) > 0.1) and (abs(dx) < 0.1)
    instance_data.vertical_shot = is_vertical

    return Projectile.spawn(world, spawn_x, spawn_y, dx, dy, projectile_type, instance_data)
end

return Projectile
