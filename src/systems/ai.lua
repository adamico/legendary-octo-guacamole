local AI = require("src/ai")
local AISystem = {}

-- Enemy AI system: orchestrates AI updates for all enemies
-- Each AI profile handles nil player gracefully (idle/wander behavior)
-- @param world - ECS world
-- @param player - Player entity (may be nil if player is dead)
function AISystem.update(world, player)
   -- Execute AI dispatch for all enemies
   world.sys("enemy", function(entity)
      AI.dispatch(entity, player)
   end)()
end

return AISystem
