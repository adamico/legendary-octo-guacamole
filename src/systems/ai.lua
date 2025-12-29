local AI = require("src/ai")
local AISystem = {}

-- AI system: orchestrates AI updates for enemies and minions
-- Each AI profile handles nil player gracefully (idle/wander behavior)
-- @param world - ECS world
-- @param player - Player entity (may be nil if player is dead)
function AISystem.update(world, player)
   -- Execute AI dispatch for all enemies
   world.sys("enemy", function(entity)
      AI.dispatch(entity, player)
   end)()

   -- Execute AI dispatch for all minions
   world.sys("minion", function(entity)
      AI.dispatch_minion(entity)
   end)()
end

return AISystem
