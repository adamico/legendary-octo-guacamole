-- Pickup entity factory (picobloc version)
-- All pickup types are defined as pure data in GameConstants.Pickup
local GameConstants = require("src/game/game_config")
local EntityUtils = require("src/utils/entity_utils")

local Pickup = {}

-- Unified spawn function using Type Object pattern
--- @param world ECSWorld - picobloc World
--- @param x number - spawn x position
--- @param y number - spawn y position
--- @param pickup_type string - type key in GameConstants.Pickup
--- @param instance_data table - optional table with instance-specific overrides
function Pickup.spawn(world, x, y, pickup_type, instance_data)
    instance_data = instance_data or {}

    local config = GameConstants.Pickup[pickup_type]
    if not config then
        Log.error("Attempted to spawn unknown pickup type: "..tostring(pickup_type))
        return nil
    end

    -- Parse tags from config
    local tag_set = EntityUtils.parse_tags(config.tags)

    local direction = instance_data.direction

    -- Build entity with centralized component builders
    local entity = {
        -- Type identifier
        type = {value = config.entity_type or "Pickup"},
        pickup_type = {value = pickup_type},

        -- Transform
        position = {x = x, y = y},
        size = EntityUtils.build_size(config),

        -- Optional velocity (for projectile pickups that fall)
        velocity = EntityUtils.build_velocity(),

        -- Collision
        collidable = EntityUtils.build_collidable(config, {
            map_collidable = false,
            w = 12,
            h = 12,
            ox = 2,
            oy = 2
        }),

        -- Pickup effect
        pickup_effect = {
            effect = config.pickup_effect or "health",
            amount = config.amount or instance_data.amount or 1,
            recovery_amount = config.recovery_amount or instance_data.recovery_amount or 0,
            xp_amount = instance_data.xp_amount or 0,
        },

        -- Visuals
        shadow = EntityUtils.build_shadow(config),
        drawable = EntityUtils.build_drawable(config, direction),
    }

    -- Apply parsed tags
    EntityUtils.apply_tags(entity, tag_set)

    -- Add z-axis data for falling pickups
    if instance_data.z then
        entity.projectile_physics = {
            z = instance_data.z,
            vel_z = 0,
            gravity_z = -0.1,
            age = 0,
            max_age = 9999,
        }
    end

    local id = world:add_entity(entity)
    return id
end

-- Convenience: Spawn simple health pickup (from enemy deaths)
function Pickup.spawn_health(world, x, y, amount)
    return Pickup.spawn(world, x, y, "HealthPickup", {
        recovery_amount = amount,
    })
end

return Pickup
