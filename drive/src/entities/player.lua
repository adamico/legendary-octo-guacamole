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
        -- Movement properties (BoI-style: instant response, almost no slide)
        accel = 1.2,
        max_speed = 2,
        friction = 0.5,
        vel_x = 0,
        vel_y = 0,
        sub_x = 0,
        sub_y = 0,
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
    }
    return world.ent(
        "player,controllable,collidable,velocity,acceleration,health,shooter,drawable,animatable,shadow,spotlight,sprite",
        player)
end

return Player
