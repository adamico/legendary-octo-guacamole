-- AI module aggregator
local chaser = require("ai/chaser_behavior")
local shooter = require("ai/shooter_behavior")
local dasher = require("ai/dasher_behavior")
local wanderer = require("ai/wanderer_behavior")

local AI = {}

AI.chaser = chaser
AI.shooter = shooter
AI.dasher = dasher
AI.wanderer = wanderer

--- Main AI dispatch function to route to specific behaviors
-- @param entity The entity processing AI
-- @param player The player entity (for targeting)
function AI.dispatch(entity, player)
   local enemy_type = entity.enemy_type
   if enemy_type == "Skulker" or enemy_type == "Skull" then
      AI.chaser(entity, player)
   elseif enemy_type == "Shooter" then
      AI.shooter(entity, player)
   elseif enemy_type == "Dasher" then
      AI.dasher(entity, player)
   end
end

return AI
