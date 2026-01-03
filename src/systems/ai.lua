local AI = require("src/ai")
local PathFollow = require("src/ai/primitives/path_follow")
local AISystem = {}

-- AI system: orchestrates AI updates for enemies and minions
-- Each AI profile handles nil player gracefully (idle/wander behavior)
-- @param world - ECS world
-- @param player - Player entity (may be nil if player is dead)
function AISystem.update(world, player)
   -- OPTIMIZATION: Reset pathfinding frame budget at start of each update
   PathFollow.reset_frame_budget()

   -- Execute AI dispatch for all enemies
   world.sys("enemy", function(entity)
      AI.dispatch(entity, player)

      -- Boss minion summoning: if boss AI set summon_pending, spawn minions
      if entity.summon_pending then
         entity.summon_pending = false
         local Entities = require("src/entities")
         local summon_count = entity.summon_count or 2
         local max_skulkers = 6 -- Hard cap on skulkers in the room

         -- Count existing Skulkers
         local skulker_count = 0
         world.sys("enemy", function(e)
            if e.enemy_type == "Skulker" and not e.dead then
               skulker_count = skulker_count + 1
            end
         end)()

         -- Calculate how many we can spawn without exceeding cap
         local spawn_allowed = max(0, max_skulkers - skulker_count)
         local actual_spawn = min(summon_count, spawn_allowed)

         if actual_spawn > 0 then
            Log.info("Boss summoning: "..actual_spawn.." skulkers (cap: "..skulker_count.."/"..max_skulkers..")")

            -- Spawn Skulker enemies around the boss
            for i = 1, actual_spawn do
               local offset_x = (rnd(1) - 0.5) * 64
               local offset_y = (rnd(1) - 0.5) * 64
               Entities.spawn_enemy(world, entity.x + offset_x, entity.y + offset_y, "Skulker")
            end
         end
      end
   end)()

   -- Execute AI dispatch for all minions
   world.sys("minion", function(entity)
      AI.dispatch_minion(entity, world)
   end)()
end

return AISystem
