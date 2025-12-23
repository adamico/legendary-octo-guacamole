-- Main entities module: aggregates all entity factories
local Player = require("player")
local Projectile = require("projectile")
local Enemy = require("enemy")
local Pickup = require("pickup")
local Shadow = require("shadow")


local Entities = {}

Entities.spawn_player = Player.spawn
-- Generic projectile spawn (pass projectile_type and instance_data)
Entities.spawn_projectile = Projectile.spawn
-- Convenience aliases for specific projectile types
Entities.spawn_laser = function(world, x, y, dx, dy, instance_data)
    return Projectile.spawn(world, x, y, dx, dy, "Laser", instance_data)
end
Entities.spawn_enemy_projectile = function(world, x, y, dx, dy)
    return Projectile.spawn(world, x, y, dx, dy, "EnemyBullet")
end
Entities.spawn_pickup_projectile = Pickup.spawn_projectile
Entities.spawn_health_pickup = Pickup.spawn_health
Entities.spawn_enemy = Enemy.spawn
Entities.spawn_shadow = Shadow.spawn

return Entities
