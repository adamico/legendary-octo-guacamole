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
   end)()
end

return Timers
