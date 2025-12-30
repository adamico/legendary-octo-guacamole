-- Main entities module: aggregates all entity factories
local Player = require("src/entities/player")
local Projectile = require("src/entities/projectile")
local Enemy = require("src/entities/enemy")
local Pickup = require("src/entities/pickup")
local Obstacle = require("src/entities/obstacle")
local Bomb = require("src/entities/bomb")
local Explosion = require("src/entities/explosion")
local Minion = require("src/entities/minion")

local Entities = {}

Entities.spawn_player = Player.spawn
Entities.spawn_enemy = Enemy.spawn
Entities.spawn_obstacle = Obstacle.spawn

-- Bomb spawners
Entities.spawn_bomb = Bomb.spawn
Entities.spawn_explosion = Explosion.spawn
Entities.spawn_explosion_grid = Explosion.spawn_grid

-- Projectile spawners (convenience wrappers for Type Object pattern)
Entities.spawn_player_projectile = function(world, x, y, dx, dy, instance_data)
    return Projectile.spawn(world, x, y, dx, dy, "Egg", instance_data)
end
Entities.spawn_enemy_projectile = function(world, x, y, dx, dy)
    return Projectile.spawn(world, x, y, dx, dy, "EnemyBullet")
end
Entities.spawn_projectile_from_origin = Projectile.spawn_from_origin

-- Pickup spawners (convenience wrappers for Type Object pattern)
Entities.spawn_pickup_projectile = Pickup.spawn_projectile
Entities.spawn_health_pickup = Pickup.spawn_health

-- Random pickup spawn (for destructibles, etc.)
-- Currently only spawns HealthPickup since ProjectilePickup requires special data
Entities.spawn_pickup = function(world, x, y, pickup_type)
    if pickup_type then
        return Pickup.spawn(world, x, y, pickup_type)
    else
        -- Random from available types (only HealthPickup for now)
        return Pickup.spawn_health(world, x, y)
    end
end

-- Minion spawners
Entities.spawn_chick = function(world, x, y, instance_data)
    return Minion.spawn(world, x, y, "Chick", instance_data)
end

Entities.spawn_minion = function(world, x, y, minion_type, instance_data)
    return Minion.spawn(world, x, y, minion_type, instance_data)
end

Entities.spawn_egg = function(world, x, y, instance_data)
    return Minion.spawn(world, x, y, "Egg", instance_data)
end

Entities.spawn_yolk_splat = function(world, x, y, instance_data)
    return Minion.spawn(world, x, y, "YolkSplat", instance_data)
end

return Entities
