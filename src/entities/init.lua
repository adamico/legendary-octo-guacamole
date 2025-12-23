-- Main entities module: aggregates all entity factories
local Player = require("player")
local Projectile = require("projectile")
local Enemy = require("enemy")
local Pickup = require("pickup")
local Shadow = require("shadow")


local Entities = {}

Entities.spawn_player = Player.spawn
Entities.spawn_projectile = Projectile.spawn
Entities.spawn_enemy_projectile = Projectile.spawn_enemy
Entities.spawn_pickup_projectile = Pickup.spawn_projectile
Entities.spawn_health_pickup = Pickup.spawn_health
Entities.spawn_enemy = Enemy.spawn
Entities.spawn_shadow = Shadow.spawn

return Entities
