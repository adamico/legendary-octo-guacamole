-- Chick AI behavior (passive wandering + eating)
local Wander = require("src/ai/primitives/wander")
local SeekFood = require("src/ai/primitives/seek_food")

return function(entity)
   -- If hurt, look for food first
   if entity.hp < (entity.max_hp or 1) then
      if SeekFood.update(entity, 120, 5) then
         return   -- Busy seeking/eating
      end
   end

   -- Otherwise wander
   Wander.update(entity)
end
