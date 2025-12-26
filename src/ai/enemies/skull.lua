-- Skull enemy AI profile
-- FSM: idle ↔ chasing
-- Skull is a pressure mechanic - always chases when player exists, idles when not
-- Uses: chase primitive

local machine = require("lib/lua-state-machine/statemachine")
local Chase = require("src/ai/primitives/chase")
local Emotions = require("src/systems/emotions")

-- Initialize Skull FSM on entity
local function init_fsm(entity)
   entity.skull_fsm = machine.create({
      initial = "idle",
      events = {
         {name = "spot", from = "idle",    to = "chasing"},
         {name = "lose", from = "chasing", to = "idle"},
      },
      callbacks = {
         onenterchasing = function()
            Emotions.set(entity, "alert")
         end,
         onenteridle = function()
            entity.vel_x = 0
            entity.vel_y = 0
         end,
      }
   })
end

--- Main AI update for Skull enemy type
-- @param entity The skull entity
-- @param player The player entity (target, may be nil)
local function skull_ai(entity, player)
   -- Initialize FSM if needed
   if not entity.skull_fsm then
      init_fsm(entity)
   end

   local fsm = entity.skull_fsm

   if fsm:is("idle") then
      -- Stop movement (already set by callback)
      entity.vel_x = 0
      entity.vel_y = 0

      -- Transition: player exists
      if player then
         fsm:spot()
      end
   elseif fsm:is("chasing") then
      -- Transition: player gone
      if not player then
         fsm:lose()
      else
         -- Chase the player
         Chase.toward(entity, player.x, player.y)
      end
   end
end

return skull_ai
