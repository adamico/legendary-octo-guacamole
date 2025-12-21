-- Player entity factory
local GameConstants = require("constants")

local Player = {}

function Player.spawn(world, x, y)
    local player = {
        type = "Player",
        x = x,
        y = y,
        width = 16,
        height = 16,
        -- Hitbox properties (smaller than sprite for forgiving collisions)
        hitbox_width = GameConstants.Player.hitbox_width,
        hitbox_height = GameConstants.Player.hitbox_height,
        hitbox_offset_x = GameConstants.Player.hitbox_offset_x,
        hitbox_offset_y = GameConstants.Player.hitbox_offset_y,
        shadow_offset = GameConstants.Player.shadow_offset or 0,
        shadow_offsets = GameConstants.Player.shadow_offsets,
        shadow_width = GameConstants.Player.shadow_width,
        shadow_height = GameConstants.Player.shadow_height,
        shadow_widths = GameConstants.Player.shadow_widths,
        shadow_heights = GameConstants.Player.shadow_heights,
        -- Movement properties (BoI-style: instant response, almost no slide)
        accel = 1.2,
        max_speed = 2,
        friction = 0.5,
        vel_x = 0,
        vel_y = 0,
        sub_x = 0,
        sub_y = 0,
        dir_x = 0,
        dir_y = 1, -- Default facing down
        sprite_index = GameConstants.Player.sprite_index_offsets.down,
        -- Health components
        hp = GameConstants.Player.max_health,
        max_hp = GameConstants.Player.max_health,
        shot_cost = GameConstants.Player.shot_cost,
        recovery_percent = GameConstants.Player.recovery_percent,
        regen_rate = GameConstants.Player.regen_rate,
        regen_delay = GameConstants.Player.regen_delay,
        time_since_shot = 0,
        overflow_hp = 0,
        shoot_cooldown = 0,
        invuln_timer = 0, -- Frames of invulnerability remaining after taking damage
    }
    local ent = world.ent(
        "player,controllable,collidable,velocity,acceleration,health,shooter,drawable,animatable,spotlight,sprite",
        player)

    local Shadow = require("shadow")
    Shadow.spawn(world, ent)

    return ent
end

return Player
