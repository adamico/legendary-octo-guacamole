-- Game Configuration Aggregator
-- Imports and merges all config sub-modules into a single GameConstants table

-- Load global tile constants (sets global variables)
require("src/game/config/tiles")

-- Load modular configs
local player = require("src/game/config/player")
local entities = require("src/game/config/entities")
local obstacles = require("src/game/config/obstacles")
local effects = require("src/game/config/effects")
local pickups = require("src/game/config/pickups")
local mutations = require("src/game/config/mutations")
local ui = require("src/game/config/ui")
local controls_config = require("src/game/config/controls")
local collision = require("src/game/config/collision")

-- Build unified GameConstants table
local GameConstants = {
   -- Core
   title = "Pizak",

   -- Player
   Player = player,

   -- Entities (from entities.lua)
   Projectile = entities.Projectile,
   Enemy = entities.Enemy,
   Minion = entities.Minion,

   -- Pickups (from pickups.lua)
   Pickup = pickups.Pickup,

   -- Obstacles (from obstacles.lua)
   Obstacle = obstacles.Obstacle,

   -- Mutations (from mutations.lua)
   Mutations = mutations,

   -- Effects (from effects.lua)
   PlacedBomb = effects.PlacedBomb,
   Explosion = effects.Explosion,
   Emotions = effects.Emotions,
   FloatingText = effects.FloatingText,

   -- UI (from ui.lua)
   Hud = ui.Hud,
   Minimap = ui.Minimap,
   XpBar = ui.XpBar,

   -- Controls (from controls.lua)
   buttons = controls_config.buttons,
   controls = controls_config.controls,

   -- Collision (from collision.lua)
   CollisionLayers = collision.CollisionLayers,
   CollisionMasks = collision.CollisionMasks,
   EntityCollisionLayer = collision.EntityCollisionLayer,
}

return GameConstants
