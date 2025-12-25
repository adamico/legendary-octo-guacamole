local AI = {}
local chaser_behavior = require("chaser")
local shooter_behavior = require("shooter")
local dasher_behavior = require("dasher")

-- Enemy AI system: simple chase behavior
function AI.update(entity)
   -- Find player
   local player = nil
   world.sys("player", function(p) player = p end)()

   if not player then
      entity.vel_x = 0
      entity.vel_y = 0
      entity.dir_x = 0
      entity.dir_y = 0
      return
   end

   if entity.enemy_type == "Skulker" or entity.enemy_type == "Skull" then
      chaser_behavior(entity, player)
   elseif entity.enemy_type == "Shooter" then
      shooter_behavior(entity, player)
   elseif entity.enemy_type == "Dasher" then
      dasher_behavior(entity, player)
   end
end

return AI
