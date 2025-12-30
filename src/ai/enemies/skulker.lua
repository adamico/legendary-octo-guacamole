-- Skulker enemy AI profile
-- FSM: wandering <-> chasing <-> puzzled
-- Uses: wander primitive, chase primitive

local machine = require("lib/lua-state-machine/statemachine")
local Wander = require("src/ai/primitives/wander")
local Chase = require("src/ai/primitives/chase")
local Emotions = require("src/systems/emotions")
local HitboxUtils = require("src/utils/hitbox_utils")

local PUZZLED_DURATION = 60 -- frames to stay puzzled before wandering

-- Initialize Skulker FSM on entity
local function init_fsm(entity)
   entity.skulker_fsm = machine.create({
      initial = "wandering",
      events = {
         {name = "spot",   from = "wandering", to = "chasing"},
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
--- @param entity The skulker entity
--- @param player The player entity (target)
local function skulker_ai(entity, player)
   -- Initialize FSM if needed
   if not entity.skulker_fsm then
      init_fsm(entity)
   end

   local fsm = entity.skulker_fsm
   local vision_range = entity.vision_range

   -- Calculate distance to player (treat nil player as infinitely far)
   local in_range = false
   if player then
      local dx = player.x - entity.x
      local dy = player.y - entity.y
      local dist = sqrt(dx * dx + dy * dy)
      -- If no vision_range defined, always chase (original behavior)
      in_range = not vision_range or dist <= vision_range
   end

   if fsm:is("wandering") then
      if in_range then
         fsm:spot()
      else
         Wander.update(entity)
      end
   elseif fsm:is("chasing") then
      if not in_range then
         fsm:lose()
         -- ... (inside skulker_ai)
      elseif player then
         local hb = HitboxUtils.get_hitbox(player)
         local tx = hb.x + hb.w / 2
         local ty = hb.y + hb.h / 2
         Chase.toward(entity, tx, ty)
      end
   elseif fsm:is("puzzled") then
      -- Stand still, wait for timer (grace period - cannot spot during this time)
      entity.vel_x = 0
      entity.vel_y = 0

      entity.puzzled_timer = entity.puzzled_timer - 1
      if entity.puzzled_timer <= 0 then
         fsm:wander()
      end
   end
end

return skulker_ai
