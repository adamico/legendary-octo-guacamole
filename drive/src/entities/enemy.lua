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
    return world.ent("enemy,velocity,collidable,drawable,sprite,health", enemy)
end

return Enemy
