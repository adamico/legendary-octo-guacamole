-- Generic health regeneration system
local HealthRegen = {}

-- Regen system: works for ANY entity with "health_regen" tag
function HealthRegen.update(world)
   world.sys("health_regen", function(entity)
      if not entity.regen_rate or entity.regen_rate <= 0 then return end

      -- Track time since trigger (shooting, damage, etc.)
      entity.time_since_regen_trigger = (entity.time_since_regen_trigger or 0) + (1 / 60)

      -- Check trigger field (default: always regen)
      local trigger_field = entity.regen_trigger_field or "time_since_shot"
      local trigger_value = entity[trigger_field] or entity.time_since_regen_trigger
      local delay = entity.regen_delay or 3.0

      if trigger_value >= delay then
         entity.hp = entity.hp + (entity.regen_rate / 60)

         -- Handle overflow (banking for player, cap for enemies)
         if entity.hp > entity.max_hp then
            if entity.overflow_banking then
               entity.overflow_hp = (entity.overflow_hp or 0) + (entity.hp - entity.max_hp)
            end
            entity.hp = entity.max_hp
         end
      end
   end)()
end

return HealthRegen
