-- Pickup entity factory

local Pickup = {}

function Pickup.spawn(world, x, y, dir_x, dir_y, amount, sprite_index)
    local pickup = {
        type = "ProjectilePickup",
        dir_x = dir_x,
        dir_y = dir_y,
        x = x,
        y = y,
        width = 8,
        height = 8,
        vel_x = 0,
        vel_y = 0,
        sub_x = 0,
        sub_y = 0,
        recovery_amount = amount,
        sprite_index = sprite_index,
    }
    return world.ent("pickup,collidable,drawable,sprite", pickup)
end

return Pickup
