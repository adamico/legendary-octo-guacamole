-- Generic countdown timer system
local Timers = {}

-- Update countdown timers on entities with "timers" tag
function Timers.update(world)
   world.sys("timers", function(entity)
      -- Invulnerability timer
      if entity.invuln_timer and entity.invuln_timer > 0 then
         entity.invuln_timer -= 1
      end

      -- Shooting cooldown
      if entity.shoot_cooldown and entity.shoot_cooldown > 0 then
         entity.shoot_cooldown -= 1
      end

      -- Melee cooldown
      if entity.melee_cooldown and entity.melee_cooldown > 0 then
         entity.melee_cooldown -= 1
      end

      -- HP drain (for minions with finite lifespan based on health)
      if entity.hp_drain_rate then
         entity.hp_drain_timer = (entity.hp_drain_timer or 0) + 1
         if entity.hp_drain_timer >= entity.hp_drain_rate then
            entity.hp_drain_timer = 0
            entity.hp = entity.hp - 1
            if entity.hp <= 0 then
               world.del(entity)
            end
         end
      end

      -- Entity lifespan (for temporary hitboxes)
      if entity.lifespan then
         entity.lifespan -= 1
         if entity.lifespan <= 0 then
            world.del(entity)
         end
      end
   end)()
end

return Timers
