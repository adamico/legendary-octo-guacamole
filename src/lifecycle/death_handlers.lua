-- Entity death behavior registry
local Entities = require("src/entities")
local GameConstants = require("src/constants")

local DeathHandlers = {}

DeathHandlers.Player = function(entity)
   Log.trace("Player died!")
   -- Future: SceneManager:gotoState("GameOver")
end

DeathHandlers.Enemy = function(entity)
   local recovery = GameConstants.Player.shot_cost * GameConstants.Player.recovery_percent
   Entities.spawn_health_pickup(world, entity.x, entity.y, recovery)
end

DeathHandlers.default = function(entity)
   Log.trace("Entity died: "..(entity.type or "Unknown"))
end

return DeathHandlers
