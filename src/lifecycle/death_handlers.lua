-- Entity death behavior registry
local Entities = require("src/entities")
local GameConstants = require("src/game/game_config")

local DeathHandlers = {}

DeathHandlers.Player = function(world, entity)
   Log.trace("Player died!")
   -- Future: SceneManager:gotoState("GameOver")
end

DeathHandlers.Enemy = function(world, entity)
   local recovery = GameConstants.Player.shot_cost * GameConstants.Player.recovery_percent
   Entities.spawn_health_pickup(world, entity.x, entity.y, recovery)
   world.del(entity)
end

DeathHandlers.default = function(world, entity)
   Log.trace("Entity died: "..(entity.type or "Unknown"))
   world.del(entity)
end

return DeathHandlers
