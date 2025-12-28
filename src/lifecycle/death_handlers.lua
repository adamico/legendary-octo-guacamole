-- Entity death behavior registry
local Entities = require("src/entities")
local GameConstants = require("src/game/game_config")
local Events = require("src/game/events")

local DeathHandlers = {}

DeathHandlers.Player = function(world, entity)
   Log.trace("Player died!")
   Events.emit(Events.GAME_OVER)
end

DeathHandlers.Enemy = function(world, entity)
   local drop_chance = entity.drop_chance or 1.0
   if rnd() < drop_chance then
      local base_recovery = GameConstants.Pickup.HealthPickup.recovery_amount
      local recovery = base_recovery * GameConstants.Player.recovery_percent
      Entities.spawn_health_pickup(world, entity.x, entity.y, recovery)
   end
   world.del(entity)
end

DeathHandlers.default = function(world, entity)
   Log.trace("Entity died: "..(entity.type or "Unknown"))
   world.del(entity)
end

return DeathHandlers
