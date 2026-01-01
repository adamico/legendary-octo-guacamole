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
local ChickAI = require("src/ai/minions/chick")
local egg_ai = require("src/ai/minions/egg")

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
   Chick = ChickAI.update, -- ChickAI is a module with update + target painting
   Egg = egg_ai,
}

-- Expose ChickAI for target painting access
AI.ChickAI = ChickAI

--- Dispatch AI update to the appropriate enemy profile
--- @param entity EntityProxy The entity to process
--- @param player EntityProxy|nil The player entity (target)
function AI.dispatch(entity, player)
   local profile = enemy_profiles[entity.enemy_type]
   if profile then
      profile(entity, player)
   end
end

--- Dispatch AI update for minions
--- @param entity EntityProxy The minion entity to process
--- @param world ECSWorld The ECS world (for spawning entities)
--- @param player EntityProxy|nil The player entity (optional)
function AI.dispatch_minion(entity, world, player)
   local profile = minion_profiles[entity.minion_type]
   if profile then
      profile(entity, world, player)
   end
end

return AI
