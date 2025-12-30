-- Chick AI behavior (passive wandering)
local Wander = require("src/ai/primitives/wander")

return function(entity)
   Wander.update(entity)
end
