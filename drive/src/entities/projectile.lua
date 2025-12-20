-- Projectile entity factory
local GameConstants = require("constants")

local Projectile = {}

function Projectile.spawn(world, x, y, dx, dy, recovery_percent, shot_cost)
    local projectile = {
        type = "Projectile",
        x = x,
        y = y,
        width = 4,
        height = 4,
        dir_x = dx,
        dir_y = dy,
        vel_x = dx * 4,
        vel_y = dy * 4,
        sub_x = 0,
        sub_y = 0,
        damage = GameConstants.Projectile.damage,
        owner = "player",
        recovery_percent = recovery_percent,
        shot_cost = shot_cost,
        sprite_index = GameConstants.Projectile.sprite_index_offsets.down,
    }
    return world.ent("projectile,velocity,collidable,drawable,sprite", projectile)
end

return Projectile
