-- Shooter enemy AI profile
-- FSM: wandering <-> engaging <-> puzzled
-- Uses: wander primitive, chase primitive (maintain_distance)

local machine = require("lib/lua-state-machine/statemachine")
local Wander = require("src/ai/primitives/wander")
local Chase = require("src/ai/primitives/chase")
local Emotions = require("src/systems/emotions")

local SHOOTER_VISION_RANGE = 200
local SHOOTER_TARGET_DIST = 100
local SHOOTER_TARGET_DIST_VARIANCE = 20
local PUZZLED_DURATION = 60 -- frames to stay puzzled before wandering

-- Initialize Shooter FSM on entity
local function init_fsm(entity)
   entity.shooter_fsm = machine.create({
      initial = "wandering",
      events = {
         {name = "spot",   from = "wandering", to = "engaging"},
         {name = "spot",   from = "puzzled",   to = "engaging"},    -- Can re-spot during puzzled
         {name = "lose",   from = "engaging",  to = "puzzled"},
         {name = "wander", from = "puzzled",   to = "wandering"},
      },
      callbacks = {
         onenterengaging = function()
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

--- Main AI update for Shooter enemy type
-- @param entity The shooter entity
-- @param player The player entity (target)
local function shooter_ai(entity, player)
   -- Initialize FSM if needed
   if not entity.shooter_fsm then
      init_fsm(entity)
   end

   local fsm = entity.shooter_fsm
   local dx = player.x - entity.x
   local dy = player.y - entity.y
   local dist = sqrt(dx * dx + dy * dy)
   local vision_range = entity.vision_range or SHOOTER_VISION_RANGE

   if fsm:is("wandering") then
      if dist <= vision_range then
         fsm:spot()
      else
         Wander.update(entity)
      end
   elseif fsm:is("engaging") then
      if dist > vision_range then
         fsm:lose()
      else
         -- Maintain ideal distance using chase primitive
         Chase.maintain_distance(entity, player.x, player.y, SHOOTER_TARGET_DIST, SHOOTER_TARGET_DIST_VARIANCE)

         -- Set shooting direction (actual spawning handled by Shooter system)
         if dist > 0 then
            entity.shoot_dir_x = dx / dist
            entity.shoot_dir_y = dy / dist
         else
            entity.shoot_dir_x = 0
            entity.shoot_dir_y = 0
         end
      end
   elseif fsm:is("puzzled") then
      -- Stand still, wait for timer
      entity.vel_x = 0
      entity.vel_y = 0

      -- Can re-spot player during puzzled state
      if dist <= vision_range then
         fsm:spot()
      else
         entity.puzzled_timer = entity.puzzled_timer - 1
         if entity.puzzled_timer <= 0 then
            fsm:wander()
         end
      end
   end
end

return shooter_ai
