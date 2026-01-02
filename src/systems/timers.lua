-- Generic countdown timer system
local GameState = require("src/game/game_state")
local Timers = {}

--- Update countdown timers on entities with "timers" tag
--- @param world ECSWorld
function Timers.update(world)
   world:query({"timers", "health?"}, function(ids, timers, health)
      -- REVIEW: maybe we should make it dynamically discover defined timers?
      for i = ids.first, ids.last do
         -- Invulnerability timer
         if timers.invuln_timer[i] and timers.invuln_timer[i] > 0 then
            timers.invuln_timer[i] = timers.invuln_timer[i] - 1
         end

         -- Shooting cooldown
         if timers.shoot_cooldown[i] and timers.shoot_cooldown[i] > 0 then
            timers.shoot_cooldown[i] = timers.shoot_cooldown[i] - 1
         end

         -- Melee cooldown
         if timers.melee_cooldown and timers.melee_cooldown[i] and timers.melee_cooldown[i] > 0 then
            timers.melee_cooldown[i] = timers.melee_cooldown[i] - 1
         end

         -- Stun timer
         if timers.stun_timer and timers.stun_timer[i] and timers.stun_timer[i] > 0 then
            timers.stun_timer[i] = timers.stun_timer[i] - 1
         end

         -- Slow timer
         if timers.slow_timer and timers.slow_timer[i] and timers.slow_timer[i] > 0 then
            timers.slow_timer[i] = timers.slow_timer[i] - 1
         end
         -- Lifespan (for temporary hitboxes)
         -- Only process if lifespan > 0 (0 means "not using lifespan")
         if timers.lifespan and timers.lifespan[i] and timers.lifespan[i] > 0 then
            timers.lifespan[i] = timers.lifespan[i] - 1
            if timers.lifespan[i] <= 0 then
               world:remove_entity(ids[i])
            end
         end
      end
   end)

   -- Separate query for HP drain to include 'hp_drain' component
   world:query({"timers", "hp_drain", "health"}, function(ids, timers, drain, health)
      local godmode = GameState.cheats.godmode
      if godmode then return end

      for i = ids.first, ids.last do
         local rate = drain.hp_drain_rate[i] or 60
         local timer = timers.hp_drain_timer[i] or 0

         timer = timer + 1
         if timer >= rate then
            timer = 0
            if health.hp[i] > 0 then
               health.hp[i] = health.hp[i] - 1
               if health.hp[i] <= 0 then
                  world:remove_entity(ids[i])
               end
            end
         end
         timers.hp_drain_timer[i] = timer
      end
   end)
end

return Timers
