-- Skull enemy AI profile
-- Simple: always chase player (no wander, no puzzled state)
-- Uses: chase primitive

local Chase = require("src/ai/primitives/chase")

--- Main AI update for Skull enemy type
-- @param entity The skull entity
-- @param player The player entity (target)
local function skull_ai(entity, player)
   -- Pure chase - no FSM needed
   Chase.toward(entity, player.x, player.y)
end

return skull_ai
