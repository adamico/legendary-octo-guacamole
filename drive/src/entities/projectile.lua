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
        palette_swaps = {
            {from = 5, to = 12},
        },
        sprite_index = GameConstants.Projectile.sprite_index_offsets[direction],
        sprite_offset_y = GameConstants.Projectile.sprite_offset_y or 0,
        shadow_offset = GameConstants.Projectile.shadow_offset or 0,
        shadow_offsets = GameConstants.Projectile.shadow_offsets,
        shadow_width = GameConstants.Projectile.shadow_width,
        shadow_height = GameConstants.Projectile.shadow_height,
        shadow_widths = GameConstants.Projectile.shadow_widths,
        shadow_heights = GameConstants.Projectile.shadow_heights,
    }
    local ent = world.ent("projectile,velocity,collidable,drawable,animatable,palette_swappable", projectile)

    local Shadow = require("shadow")
    Shadow.spawn(world, ent)

    return ent
end

function Projectile.spawn_enemy(world, x, y, dx, dy)
    local config = GameConstants.EnemyProjectile
    local projectile = {
        type = "EnemyProjectile",
        x = x,
        y = y,
        width = 16,
        height = 16,
        hitbox_width = config.hitbox_width,
        hitbox_height = config.hitbox_height,
        hitbox_offset_x = config.hitbox_offset_x,
        hitbox_offset_y = config.hitbox_offset_y,
        dir_x = dx,
        dir_y = dy,
        vel_x = dx * config.speed,
        vel_y = dy * config.speed,
        sub_x = 0,
        sub_y = 0,
        damage = config.damage,
        owner = "enemy",
        animations = config.animations,
        sprite_offset_y = config.sprite_offset_y or 0,
        shadow_offset = config.shadow_offset or 0,
        shadow_offsets = config.shadow_offsets,
        shadow_width = config.shadow_width,
        shadow_height = config.shadow_height,
        shadow_widths = config.shadow_widths,
        shadow_heights = config.shadow_heights,
    }
    local ent = world.ent("projectile,velocity,collidable,drawable,animatable", projectile)

    local Shadow = require("shadow")
    Shadow.spawn(world, ent)

    return ent
end

return Projectile
