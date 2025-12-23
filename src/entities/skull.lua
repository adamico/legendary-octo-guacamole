-- Skull entity factory
local GameConstants = require("constants")

local Skull = {}

function Skull.spawn(world, x, y)
    local skull = {
        type = "Skull",
        enemy_type = "Skull",
        x = x,
        y = y,
        width = 16,
        height = 16,
        hitbox_width = 16,
        hitbox_height = 16,
        hitbox_offset_x = 0,
        hitbox_offset_y = 0,
        shadow_offset = 0,
        shadow_width = 13,
        shadow_height = 3,
        hp = 1,
        max_hp = 1,
        speed = 0.6,
        contact_damage = 20,
        vel_x = 0,
        vel_y = 0,
        sub_x = 0,
        sub_y = 0,
        dir_x = 0,
        dir_y = 1,
        sprite_index = 117,
        flip_x = false
    }

    local ent = world.ent("skull,enemy,velocity,collidable,health,drawable,sprite,middleground", skull)

    local Shadow = require("shadow")
    Shadow.spawn(world, ent)

    return ent
end

return Skull
