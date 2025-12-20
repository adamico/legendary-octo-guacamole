-- Entities module: entity factory functions
local Entities = {}

-- Create a player entity
function Entities.spawn_player(world, x, y)
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

-- Create a projectile entity
function Entities.spawn_projectile(world, x, y, dx, dy, recovery_percent, shot_cost)
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
        recovery_percent = recovery_percent or 0.8,
        shot_cost = shot_cost or 20,
        sprite_index = 77,
    }
    return world.ent("projectile,velocity,collidable,drawable,sprite", projectile)
end

-- Create a pickup entity (stuck projectile)
function Entities.spawn_pickup_projectile(world, x, y, amount)
    local pickup = {
        type = "ProjectilePickup",
        x = x,
        y = y,
        width = 8,
        height = 8,
        vel_x = 0,
        vel_y = 0,
        sub_x = 0,
        sub_y = 0,
        recovery_amount = amount or 4,
        sprite_index = 77,
    }
    return world.ent("pickup,collidable,drawable,sprite", pickup)
end

-- Create an enemy entity
function Entities.spawn_enemy(world, x, y, enemy_type)
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

return Entities
