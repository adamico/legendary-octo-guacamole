-- Physics module aggregator
local Collision = require("src/physics/collision")
local SpatialGrid = require("src/physics/spatial_grid")
local CollisionFilter = require("src/physics/collision_filter")
local Handlers = require("src/physics/handlers")

local Physics = {}

Physics.collision = Collision
Physics.SpatialGrid = SpatialGrid
Physics.CollisionFilter = CollisionFilter
Physics.Handlers = Handlers

-- Re-export common functions for convenience
Physics.resolve_entities = Collision.resolve_entities
Physics.update_spatial_grid = Collision.update_spatial_grid
Physics.resolve_map = Collision.resolve_map

return Physics
