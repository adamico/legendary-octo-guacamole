-- Collision Handlers Aggregator
-- Imports and merges all handler sub-modules into a unified Handlers table

local PickupHandlers = require("src/physics/handlers/pickup_handlers")
local CombatHandlers = require("src/physics/handlers/combat_handlers")
local ObstacleHandlers = require("src/physics/handlers/obstacle_handlers")
local MapHandlers = require("src/physics/handlers/map_handlers")

local Handlers = {
    entity = {},
    map = {}
}

-- Register all handlers from sub-modules
PickupHandlers.register(Handlers)
CombatHandlers.register(Handlers)
ObstacleHandlers.register(Handlers)
MapHandlers.register(Handlers)

return Handlers
