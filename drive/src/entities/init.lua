-- Main entities module: aggregates all entity factories
local Player = require("player")
local Projectile = require("projectile")
local Enemy = require("enemy")
local Pickup = require("pickup")
local Shadow = require("shadow")

local Entities = {}

-- Player factory
Entities.spawn_player = Player.spawn

-- Projectile factory
Entities.spawn_projectile = Projectile.spawn
Entities.spawn_enemy_projectile = Projectile.spawn_enemy

-- Pickup factory
Entities.spawn_pickup_projectile = Pickup.spawn

-- Enemy factory
Entities.spawn_enemy = Enemy.spawn

-- Shadow factory
Entities.spawn_shadow = Shadow.spawn

return Entities
