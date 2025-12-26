-- Pickup entity factory (Type Object pattern)
-- All pickup types are defined as pure data in GameConstants.Pickup
-- This factory simply instantiates entities from their type config
local GameConstants = require("constants")
local EntityUtils = require("utils/entity_utils")

local Pickup = {}

-- Unified spawn function using Type Object pattern
-- @param world - ECS world
-- @param x, y - spawn position
-- @param pickup_type - type key in GameConstants.Pickup (e.g., "ProjectilePickup", "HealthPickup")
-- @param instance_data - optional table with instance-specific overrides
function Pickup.spawn(world, x, y, pickup_type, instance_data)
    instance_data = instance_data or {}

    local config = GameConstants.Pickup[pickup_type]
    if not config then
        Log.error("Attempted to spawn unknown pickup type: "..tostring(pickup_type))
        return nil
    end

    local direction = instance_data.direction

    -- 1. Base identity and physics state
    local pickup = {
        type = config.entity_type or "Pickup",
        pickup_type = pickup_type,
        x = x,
        y = y,
        vel_x = 0,
        vel_y = 0,
        sub_x = 0,
        sub_y = 0,
    }

    -- 2. Bulk copy all non-table values from config (stats, bounds, offsets)
    for k, v in pairs(config) do
        if type(v) ~= "table" then
            pickup[k] = v
        end
    end

    -- 3. Sprite: use instance override, or direction-based lookup, or static sprite
    if instance_data.sprite_index then
        pickup.sprite_index = instance_data.sprite_index
    elseif config.sprite_index_offsets and direction then
        pickup.sprite_index = config.sprite_index_offsets[direction]
    else
        pickup.sprite_index = config.sprite_index or 0
    end

    -- 4. Hitbox: special handling for projectile-based pickups (uses Laser hitbox)
    if config.hitbox_from_projectile then
        pickup.hitbox = GameConstants.Projectile.Laser.hitbox
    end

    -- 5. Apply instance-specific overrides
    for k, v in pairs(instance_data) do
        pickup[k] = v
    end

    -- 6. Create entity with tags from config
    return world.ent(config.tags, pickup)
end

-- Convenience: Spawn projectile-based pickup (from wall collisions)
function Pickup.spawn_projectile(world, x, y, dir_x, dir_y, amount, sprite_index)
    local direction = EntityUtils.get_direction_name(dir_x, dir_y)
    return Pickup.spawn(world, x, y, "ProjectilePickup", {
        direction = direction,
        dir_x = dir_x,
        dir_y = dir_y,
        recovery_amount = amount,
        sprite_index = sprite_index,
    })
end

-- Convenience: Spawn simple health pickup (from enemy deaths)
function Pickup.spawn_health(world, x, y, amount)
    return Pickup.spawn(world, x, y, "HealthPickup", {
        recovery_amount = amount,
    })
end

return Pickup
