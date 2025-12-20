-- Main entities module: aggregates all entity factories
local Player = require("player")
local Projectile = require("projectile")
local Enemy = require("enemy")
local Pickup = require("pickup")

local Entities = {}

-- Player factory
Entities.spawn_player = Player.spawn

-- Projectile factory
Entities.spawn_projectile = Projectile.spawn

-- Pickup factory
Entities.spawn_pickup_projectile = Pickup.spawn

-- Enemy factory
Entities.spawn_enemy = Enemy.spawn

return Entities
