local AI = require("src/ai")
local AISystem = {}

-- Enemy AI system: orchestrates AI updates for all enemies
function AISystem.update(world)
   -- Find player once per frame
   local player = nil
   world.sys("player", function(p) player = p end)()

   -- If no player, stop all enemies
   if not player then
      world.sys("enemy", function(entity)
         entity.vel_x = 0
         entity.vel_y = 0
         entity.dir_x = 0
         entity.dir_y = 0
      end)()
      return
   end

   -- Execute AI dispatch for all enemies
   world.sys("enemy", function(entity)
      AI.dispatch(entity, player)
   end)()
end

return AISystem
