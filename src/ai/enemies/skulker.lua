-- Skulker enemy AI profile
-- FSM: wandering <-> chasing <-> puzzled
-- Uses: wander primitive, chase primitive

local machine = require("lib/lua-state-machine/statemachine")
local Wander = require("src/ai/primitives/wander")
local Chase = require("src/ai/primitives/chase")
local Emotions = require("src/systems/emotions")

local PUZZLED_DURATION = 60 -- frames to stay puzzled before wandering

-- Initialize Skulker FSM on entity
local function init_fsm(entity)
   entity.skulker_fsm = machine.create({
      initial = "wandering",
      events = {
         {name = "spot",   from = "wandering", to = "chasing"},
         {name = "spot",   from = "puzzled",   to = "chasing"},    -- Can re-spot during puzzled
         {name = "lose",   from = "chasing",   to = "puzzled"},
         {name = "wander", from = "puzzled",   to = "wandering"},
      },
      callbacks = {
         onenterchasing = function()
            Emotions.set(entity, "alert")
            Wander.reset(entity)
         end,
         onenterpuzzled = function()
            Emotions.set(entity, "confused")
            entity.puzzled_timer = PUZZLED_DURATION
            entity.vel_x = 0
            entity.vel_y = 0
         end,
         onenterwandering = function()
            -- No emotion on entering wandering, puzzled already showed "?"
         end,
      }
   })
end

--- Main AI update for Skulker enemy type
-- @param entity The skulker entity
-- @param player The player entity (target)
local function skulker_ai(entity, player)
   -- Initialize FSM if needed
   if not entity.skulker_fsm then
      init_fsm(entity)
   end

   local fsm = entity.skulker_fsm
   local dx = player.x - entity.x
   local dy = player.y - entity.y
   local dist = sqrt(dx * dx + dy * dy)
   local vision_range = entity.vision_range

   -- If no vision_range defined, always chase (original behavior)
   local in_range = not vision_range or dist <= vision_range

   if fsm:is("wandering") then
      if in_range then
         fsm:spot()
      else
         Wander.update(entity)
      end
   elseif fsm:is("chasing") then
      if not in_range then
         fsm:lose()
      else
         Chase.toward(entity, player.x, player.y)
      end
   elseif fsm:is("puzzled") then
      -- Stand still, wait for timer
      entity.vel_x = 0
      entity.vel_y = 0

      -- Can re-spot player during puzzled state
      if in_range then
         fsm:spot()
      else
         entity.puzzled_timer = entity.puzzled_timer - 1
         if entity.puzzled_timer <= 0 then
            fsm:wander()
         end
      end
   end
end

return skulker_ai
