-- Pickup entity factory
local GameConstants = require("constants")

local Pickup = {}

function Pickup.spawn(world, x, y, dir_x, dir_y, amount, sprite_index)
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

    local pickup = {
        type = "ProjectilePickup",
        dir_x = dir_x,
        dir_y = dir_y,
        x = x,
        y = y,
        width = 16,
        height = 16,
        -- Direction-based hitbox (same as projectile)
        hitbox = GameConstants.Projectile.hitbox,
        direction = direction,
        vel_x = 0,
        vel_y = 0,
        sub_x = 0,
        sub_y = 0,
        recovery_amount = amount,
        sprite_index = sprite_index,
    }
    return world.ent("pickup,collidable,drawable,sprite,background", pickup)
end

return Pickup
