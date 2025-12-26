-- Physics module aggregator
local Collision = require("physics/collision")
local SpatialGrid = require("physics/spatial_grid")
local CollisionFilter = require("physics/collision_filter")
local Handlers = require("physics/handlers")

local Physics = {}

Physics.collision = Collision
Physics.SpatialGrid = SpatialGrid
Physics.CollisionFilter = CollisionFilter
Physics.Handlers = Handlers

-- Re-export common functions for convenience
Physics.resolve_entities = Collision.resolve_entities
Physics.resolve_map = Collision.resolve_map
Physics.acceleration = Collision.acceleration -- Wait, acceleration is in physics/init.lua? No, let me check.

return Physics
