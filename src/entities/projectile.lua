-- Projectile entity factory (picobloc version)
-- All projectile types are defined as pure data in GameConstants.Projectile
local GameConstants = require("src/game/game_config")
local EntityUtils = require("src/utils/entity_utils")

local Projectile = {}

-- Unified spawn function using Type Object pattern
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

    -- Parse tags from comma-separated config string
    local tag_set = {}
    for tag in all(split(config.tags or "", ",")) do
        tag_set[tag] = true
    end

    local direction = EntityUtils.get_direction_name(dx, dy)
    local speed = instance_data.speed or config.speed

    -- Calculate initial Z and gravity
    -- REVIEW: can this be refactored with timers?
    local initial_z = instance_data.z or config.z
    local max_age = instance_data.lifetime or 60
    local drop_duration = max_age * 0.25
    if drop_duration < 1 then drop_duration = 1 end
    local gravity_z = (-2 * initial_z) / (drop_duration * drop_duration)

    -- Determine sprite index
    local sprite_index = EntityUtils.get_sprite_index(config, direction)

    -- Build entity with components
    local entity = {
        -- Type identifier
        type = {value = config.entity_type or "Projectile"},
        projectile_type = {value = projectile_type},

        -- Owner
        projectile_owner = {
            owner = config.owner or "player",
        },

        -- Z-axis physics
        position = {x = x, y = y, z = initial_z},
        size = {width = config.width or 16, height = config.height or 16},
        direction = {
            dir_x = dx,
            dir_y = dy,
        },

        -- Movement
        velocity = {
            vel_x = dx * speed,
            vel_y = dy * speed,
            vel_z = 0,
            sub_x = 0,
            sub_y = 0,
        },

        acceleration = {
            accel = 0,
            friction = 0,
            max_speed = 0,
            gravity_z = gravity_z,
        },

        lifetime = {
            age = 0,
            max_age = max_age,
        },

        -- Collision
        collidable = {
            hitboxes = config.hitboxes or {
                w = config.hitbox_width or 8,
                h = config.hitbox_height or 8,
                ox = config.hitbox_offset_x or 4,
                oy = config.hitbox_offset_y or 4,
            },
            map_collidable = tag_set.map_collidable or false,
        },

        -- Combat
        projectile_combat = {
            damage = instance_data.damage or config.damage,
            knockback = instance_data.knockback or config.knockback,
        },

        -- Visuals: Shadow
        shadow = {
            shadow_offset_x = config.shadow_offset_x or 0,
            shadow_offset_y = config.shadow_offset_y or 0,
            shadow_width = config.shadow_width or 4,
            shadow_height = config.shadow_height or 3,
            shadow_offsets_x = config.shadow_offsets_x,
            shadow_offsets_y = config.shadow_offsets_y,
            shadow_widths = config.shadow_widths,
            shadow_heights = config.shadow_heights,
        },

        -- Visuals: Drawable
        drawable = {
            outline_color = nil,
            sort_offset_y = 0,
            sprite_index = sprite_index,
            flip_x = false,
            flip_y = false,
        },

        -- Visuals: Animation
        animatable = {
            animations = config.animations,
            sprite_index_offsets = config.sprite_index_offsets,
        },
    }

    -- Copy all parsed tags into entity
    for tag, _ in pairs(tag_set) do
        entity[tag] = true
    end

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
