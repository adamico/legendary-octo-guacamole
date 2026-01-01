-- Generic health regeneration system
local HealthRegen = {}

-- Regen system: works for ANY entity with "health_regen" tag
function HealthRegen.update(world)
   world:query({"health_regen", "health"}, function(ids, regen, health)
      for i = ids.first, ids.last do
         local regen_rate = regen.regen_rate[i]
         if not regen_rate or regen_rate <= 0 then
            goto continue
         end

         -- Get current HP values
         local hp = health.hp[i]
         local max_hp = health.max_hp[i]

         -- Simple regen: add fraction per frame
         hp = hp + (regen_rate / 60)

         -- Handle overflow (cap for now, banking would need player check)
         if hp > max_hp then
            hp = max_hp
         end

         health.hp[i] = hp

         ::continue::
      end
   end)
end

return HealthRegen
