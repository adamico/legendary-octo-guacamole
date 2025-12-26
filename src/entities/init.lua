-- Main entities module: aggregates all entity factories
local Player = require("entities/player")
local Projectile = require("entities/projectile")
local Enemy = require("entities/enemy")
local Pickup = require("entities/pickup")

local Entities = {}

Entities.spawn_player = Player.spawn
Entities.spawn_enemy = Enemy.spawn

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

return Entities
