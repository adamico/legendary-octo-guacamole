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
        shadow_offset = config.shadow_offset or 0,
        shadow_offsets = config.shadow_offsets,
        shadow_width = config.shadow_width,
        shadow_height = config.shadow_height,
        shadow_widths = config.shadow_widths,
        shadow_heights = config.shadow_heights,
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
    if enemy_type == "Shooter" then
        enemy.shoot_timer = config.shoot_delay
        enemy.shoot_delay = config.shoot_delay
        enemy.is_shooter = true
    end

    local ent = world.ent("enemy,velocity,collidable,health,drawable,animatable,sprite", enemy)

    local Shadow = require("shadow")
    Shadow.spawn(world, ent)

    return ent
end

return Enemy
