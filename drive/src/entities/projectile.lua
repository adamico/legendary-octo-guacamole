-- Projectile entity factory
local GameConstants = require("constants")

local Projectile = {}

function Projectile.spawn(world, x, y, dx, dy, recovery_percent, shot_cost)
    -- Determine direction name from velocity
    local direction
    if dx > 0 then
        direction = "right"
    elseif dx < 0 then
        direction = "left"
    elseif dy < 0 then
        direction = "up"
    else
        direction = "down"
    end

    local projectile = {
        type = "Projectile",
        x = x,
        y = y,
        width = 16, -- Sprite size
        height = 16,
        -- Direction-based hitbox (looked up by get_hitbox using direction)
        hitbox = GameConstants.Projectile.hitbox,
        direction = direction,
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
        sprite_index = GameConstants.Projectile.sprite_index_offsets[direction],
    }
    return world.ent("projectile,velocity,collidable,drawable,sprite", projectile)
end

return Projectile
