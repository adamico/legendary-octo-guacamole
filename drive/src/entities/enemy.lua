-- Enemy entity factory
local GameConstants = require("constants")

local Enemy = {}

function Enemy.spawn(world, x, y, enemy_type)
    enemy_type = enemy_type or "Skulker"
    local config = GameConstants.Enemy[enemy_type]

    local enemy = {
        type = "Enemy",          -- For collision handlers
        enemy_type = enemy_type, -- "Skulker", etc. for AI/sprite
        x = x,
        y = y,
        width = config.width,
        height = config.height,
        -- Hitbox properties from config
        hitbox_width = config.hitbox_width,
        hitbox_height = config.hitbox_height,
        hitbox_offset_x = config.hitbox_offset_x,
        hitbox_offset_y = config.hitbox_offset_y,
        hp = config.hp,
        max_hp = config.hp,
        speed = config.speed,
        contact_damage = config.contact_damage,
        vel_x = 0,
        vel_y = 0,
        sub_x = 0,
        sub_y = 0,
        dir_x = 0,
        dir_y = 1, -- Default facing down
        sprite_index = config.sprite_index_offsets.down,
    }
    return world.ent("enemy,velocity,collidable,health,drawable,animatable,sprite", enemy)
end

return Enemy
