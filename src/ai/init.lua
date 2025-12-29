-- AI module aggregator
-- Exposes primitives for composition and enemy-type dispatch

-- Primitives (reusable building blocks)
local Wander = require("src/ai/primitives/wander")
local Chase = require("src/ai/primitives/chase")

-- Enemy AI profiles (per-enemy-type controllers)
local skulker_ai = require("src/ai/enemies/skulker")
local skull_ai = require("src/ai/enemies/skull")
local shooter_ai = require("src/ai/enemies/shooter")
local dasher_ai = require("src/ai/enemies/dasher")

-- Minion AI profiles
local chick_ai = require("src/ai/enemies/chick")

local AI = {}

-- Expose primitives for external use (testing, custom compositions)
AI.primitives = {
   wander = Wander,
   chase = Chase,
}

-- Enemy AI lookup table (maps enemy_type to AI function)
local enemy_profiles = {
   Skulker = skulker_ai,
   Skull = skull_ai,
   Shooter = shooter_ai,
   Dasher = dasher_ai,
}

-- Minion AI lookup table (maps minion_type to AI function)
local minion_profiles = {
   Chick = chick_ai,
}

--- Dispatch AI update to the appropriate enemy profile
-- @param entity The entity to process
-- @param player The player entity (target)
function AI.dispatch(entity, player)
   local profile = enemy_profiles[entity.enemy_type]
   if profile then
      profile(entity, player)
   end
end

--- Dispatch AI update for minions
-- @param entity The minion entity to process
function AI.dispatch_minion(entity)
   local profile = minion_profiles[entity.minion_type]
   if profile then
      profile(entity)
   end
end

return AI
