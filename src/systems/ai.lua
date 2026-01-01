local AI = require("src/ai")
local PathFollow = require("src/ai/primitives/path_follow")
local EntityProxy = require("src/utils/entity_proxy")
local AISystem = {}

--- AI system: orchestrates AI updates for enemies and minions
---
--- Each AI profile handles nil player gracefully (idle/wander behavior)
---
--- @param world ECSWorld
--- @param player_id EntityID|nil
---
function AISystem.update(world, player_id)
   -- OPTIMIZATION: Reset pathfinding frame budget at start of each update
   PathFollow.reset_frame_budget()

   -- Resolve player proxy once (if player exists)
   local player_proxy = nil
   if player_id and world:entity_exists(player_id) then
      player_proxy = EntityProxy.new(world, player_id)
   end

   -- Execute AI dispatch for all enemies
   world:query({"enemy"}, function(ids)
      for i = 0, ids.count - 1 do
         local id = ids[i]
         local proxy = EntityProxy.new(world, id)
         AI.dispatch(proxy, player_proxy)
      end
   end)

   -- Execute AI dispatch for all minions
   world:query({"minion"}, function(ids)
      for i = 0, ids.count - 1 do
         local id = ids[i]
         local proxy = EntityProxy.new(world, id)
         AI.dispatch_minion(proxy, world, player_proxy)
      end
   end)
end

return AISystem
