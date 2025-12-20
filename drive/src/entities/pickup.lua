-- Pickup entity factory

local Pickup = {}

function Pickup.spawn(world, x, y, amount)
    local pickup = {
        type = "ProjectilePickup",
        x = x,
        y = y,
        width = 8,
        height = 8,
        vel_x = 0,
        vel_y = 0,
        sub_x = 0,
        sub_y = 0,
        recovery_amount = amount or 4,
        sprite_index = 77,
    }
    return world.ent("pickup,collidable,drawable,sprite", pickup)
end

return Pickup
