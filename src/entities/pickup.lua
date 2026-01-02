-- Pickup entity factory (picobloc version)
-- All pickup types are defined as pure data in GameConstants.Pickup
local GameConstants = require("src/game/game_config")
local EntityUtils = require("src/utils/entity_utils")

local Pickup = {}

-- Unified spawn function using Type Object pattern
--- @param world World - picobloc World
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

    -- Parse tags from comma-separated config string
    local tag_set = {}
    for tag in all(split(config.tags or "", ",")) do
        tag_set[tag] = true
    end

    local direction = instance_data.direction

    -- Determine sprite index
    local sprite_index = instance_data.sprite_index or EntityUtils.get_sprite_index(config, direction)

    -- Determine hitbox
    local hitbox = config.hitbox
    if config.hitbox_from_projectile then
        hitbox = GameConstants.Projectile.Egg.hitbox
    end
    if not hitbox then
        hitbox = {
            w = config.hitbox_width or 12,
            h = config.hitbox_height or 12,
            ox = config.hitbox_offset_x or 2,
            oy = config.hitbox_offset_y or 2,
        }
    end

    -- Build entity with components
    local entity = {
        -- Type identifier
        type = {value = config.entity_type or "Pickup"},
        pickup_type = {value = pickup_type},

        -- Transform
        position = {x = x, y = y},
        size = {width = config.width or 16, height = config.height or 16},

        -- Optional velocity (for projectile pickups that fall)
        velocity = {
            vel_x = 0,
            vel_y = 0,
            sub_x = 0,
            sub_y = 0,
        },

        -- Collision
        collidable = {
            hitboxes = hitbox,
            map_collidable = config.map_collidable or false, -- Pickups typically don't need map collision
        },

        -- Pickup effect
        pickup_effect = {
            effect = config.pickup_effect or "health",
            amount = config.amount or instance_data.amount or 1,
            recovery_amount = config.recovery_amount or instance_data.recovery_amount or 0,
            xp_amount = instance_data.xp_amount or 0,
        },

        -- Visuals: Shadow
        shadow = {
            shadow_offset_x = config.shadow_offset_x or 0,
            shadow_offset_y = config.shadow_offset_y or 0,
            shadow_width = config.shadow_width or 11,
            shadow_height = config.shadow_height or 3,
            shadow_offsets_x = nil,
            shadow_offsets_y = nil,
            shadow_widths = nil,
            shadow_heights = nil,
        },

        -- Visuals: Drawable
        drawable = {
            outline_color = nil,
            sort_offset_y = 0,
            sprite_index = sprite_index,
            flip_x = false,
            flip_y = false,
        },
    }

    -- Copy all parsed tags into entity
    for tag, _ in pairs(tag_set) do
        entity[tag] = true
    end

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
