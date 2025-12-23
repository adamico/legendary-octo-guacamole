-- Pickup entity factory
local GameConstants = require("constants")

local Pickup = {}

-- Helper: Create base pickup entity with common properties
local function spawn_base(config)
    local pickup = {
        type = config.type,
        pickup_type = config.pickup_type or "health",
        x = config.x,
        y = config.y,
        width = config.width or 16,
        height = config.height or 16,
        vel_x = 0,
        vel_y = 0,
        sub_x = 0,
        sub_y = 0,
        sprite_index = config.sprite_index,
    }

    -- Optional properties
    if config.hitbox then
        pickup.hitbox = config.hitbox
    else
        pickup.hitbox_width = config.hitbox_width or 12
        pickup.hitbox_height = config.hitbox_height or 12
        pickup.hitbox_offset_x = config.hitbox_offset_x or 2
        pickup.hitbox_offset_y = config.hitbox_offset_y or 2
    end

    if config.direction then pickup.direction = config.direction end
    if config.dir_x then pickup.dir_x = config.dir_x end
    if config.dir_y then pickup.dir_y = config.dir_y end
    if config.recovery_amount then pickup.recovery_amount = config.recovery_amount end

    return world.ent("pickup,collidable,drawable,sprite,background", pickup)
end

-- Spawn projectile-based pickup (from wall collisions)
function Pickup.spawn_projectile(world, x, y, dir_x, dir_y, amount, sprite_index)
    -- Determine direction name from source projectile direction
    local direction
    if dir_x > 0 then
        direction = "right"
    elseif dir_x < 0 then
        direction = "left"
    elseif dir_y < 0 then
        direction = "up"
    else
        direction = "down"
    end

    return spawn_base({
        type = "ProjectilePickup",
        pickup_type = "health",
        x = x,
        y = y,
        dir_x = dir_x,
        dir_y = dir_y,
        direction = direction,
        hitbox = GameConstants.Projectile.hitbox,
        sprite_index = sprite_index,
        recovery_amount = amount,
    })
end

-- Spawn simple health pickup (from enemy deaths)
function Pickup.spawn_health(world, x, y, amount)
    return spawn_base({
        type = "HealthPickup",
        pickup_type = "health",
        x = x,
        y = y,
        sprite_index = 64,
        recovery_amount = amount,
    })
end

return Pickup
