-- Player entity factory
local GameConstants = require("src/game/game_config")
local EntityUtils = require("src/utils/entity_utils")

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
        shadow_offset_y = GameConstants.Player.shadow_offset_y or 0,
        shadow_offset_x = GameConstants.Player.shadow_offset_x or 0,
        shadow_offsets_y = GameConstants.Player.shadow_offsets_y,
        shadow_offsets_x = GameConstants.Player.shadow_offsets_x,
        shadow_width = GameConstants.Player.shadow_width,
        shadow_height = GameConstants.Player.shadow_height,
        shadow_widths = GameConstants.Player.shadow_widths,
        shadow_heights = GameConstants.Player.shadow_heights,
        -- Movement properties (BoI-style: instant response, almost no slide)
        accel = 1.2,
        max_speed = GameConstants.Player.max_speed,
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
        max_hp_to_shot_cost_ratio = GameConstants.Player.max_hp_to_shot_cost_ratio,

        -- Calculated properties (removed to ensure dynamic calculation)
        -- shot_cost is calculated by systems based on max_hp * ratio
        recovery_percent = GameConstants.Player.recovery_percent,
        regen_rate = GameConstants.Player.regen_rate,
        regen_delay = GameConstants.Player.regen_delay,
        time_since_shot = 0,
        overflow_hp = 0,
        shoot_cooldown = 0,
        -- Combat Stats
        shot_speed = GameConstants.Player.shot_speed,
        max_hp_to_damage_ratio = GameConstants.Player.max_hp_to_damage_ratio,
        knockback = GameConstants.Player.base_knockback,
        range = GameConstants.Player.range,
        fire_rate = GameConstants.Player.fire_rate,

        melee_cooldown = 0,
        melee_cost = GameConstants.Player.melee_cost,
        invuln_timer = 0, -- Frames of invulnerability remaining after taking damage

        -- Inventory
        coins = GameConstants.Player.coins,
        keys = GameConstants.Player.keys,
        bombs = GameConstants.Player.bombs,
        -- Shooter system properties
        health_as_ammo = true, -- Shooting costs HP
        projectile_type = "Laser",
        shoot_cooldown_duration = GameConstants.Player.fire_rate,
        -- Health regen properties
        regen_trigger_field = "time_since_shot", -- Trigger for regen
        overflow_banking = true,                 -- Bank overflow HP
        -- Visual properties
        outline_color = GameConstants.Player.outline_color,
    }

    -- Create entity with shadow tag (shadow auto-spawned)
    return EntityUtils.spawn_entity(
        world,
        "player,controllable,map_collidable,collidable,velocity,acceleration,health,shooter,health_regen,timers,drawable,animatable,spotlight,sprite,shadow,middleground",
        player)
end

return Player
