-- Main entities module: aggregates all entity factories
local Player = require("src/entities/player")
local Projectile = require("src/entities/projectile")
local Enemy = require("src/entities/enemy")
local Pickup = require("src/entities/pickup")
local Obstacle = require("src/entities/obstacle")
local Bomb = require("src/entities/bomb")
local Explosion = require("src/entities/explosion")

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
    return Projectile.spawn(world, x, y, dx, dy, "Laser", instance_data)
end
Entities.spawn_enemy_projectile = function(world, x, y, dx, dy)
    return Projectile.spawn(world, x, y, dx, dy, "EnemyBullet")
end
Entities.spawn_centered_projectile = Projectile.spawn_centered

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

return Entities
