-- Wander primitive
-- Provides random wandering movement for entities without a current target
-- This is a stateful primitive that tracks wander state on the entity

local EntityUtils = require("src/utils/entity_utils")
local Emotions = require("src/systems/emotions")

local Wander = {}

-- Pick a random destination within radius of current position
local function pick_wander_target(entity)
   local radius = entity.wander_radius or 48
   local angle = rnd(1) * 2 * 3.14159             -- Random angle in radians
   local dist = rnd(radius * 0.5) + radius * 0.5  -- Between 50-100% of radius

   entity.wander_target_x = entity.x + cos(angle / (2 * 3.14159)) * dist
   entity.wander_target_y = entity.y + sin(angle / (2 * 3.14159)) * dist

   -- Set pause timer for when we reach target
   local pause_min = entity.wander_pause_min or 30
   local pause_max = entity.wander_pause_max or 90
   entity.wander_pause_duration = flr(rnd(pause_max - pause_min)) + pause_min
end

-- Initialize wandering state on entity if needed
local function init_wandering(entity)
   if not entity.wander_initialized then
      entity.wander_initialized = true
      entity.wander_state = "moving"   -- "moving" or "pausing"
      entity.wander_timer = 0
      pick_wander_target(entity)
   end
end

--- Execute wander behavior for one frame
-- Updates entity velocity and direction
-- @param entity The entity to wander
function Wander.update(entity)
   init_wandering(entity)

   local speed_mult = entity.wander_speed_mult or 0.5
   local speed = entity.speed * speed_mult

   if entity.wander_state == "pausing" then
      -- Stand still during pause
      entity.vel_x = 0
      entity.vel_y = 0

      entity.wander_timer = entity.wander_timer - 1
      if entity.wander_timer <= 0 then
         -- Done pausing, pick new target and start moving
         pick_wander_target(entity)
         entity.wander_state = "moving"
      end
   else
      -- Moving toward target
      local dx = entity.wander_target_x - entity.x
      local dy = entity.wander_target_y - entity.y
      local dist = sqrt(dx * dx + dy * dy)

      -- Check if we hit a wall last frame (flag set by collision system)
      if entity.hit_wall then
         -- Pick a new target when blocked
         pick_wander_target(entity)
         entity.hit_wall = false
         dx = entity.wander_target_x - entity.x
         dy = entity.wander_target_y - entity.y
         dist = sqrt(dx * dx + dy * dy)
      end

      if dist > 4 then
         -- Move toward target
         entity.vel_x = (dx / dist) * speed
         entity.vel_y = (dy / dist) * speed
         entity.dir_x = sgn(dx)
         entity.dir_y = sgn(dy)

         -- Update direction for animation system
         entity.current_direction = EntityUtils.get_direction_name(dx, dy, entity.current_direction)
      else
         -- Reached target, start pausing
         entity.wander_state = "pausing"
         entity.wander_timer = entity.wander_pause_duration
         entity.vel_x = 0
         entity.vel_y = 0

         -- Show idle emotion when pausing (50% chance to avoid spam)
         if rnd(1) > 0.5 then
            Emotions.set(entity, "idle")
         end
      end
   end
end

--- Reset wandering state (call when switching to combat mode)
-- @param entity The entity to reset
function Wander.reset(entity)
   entity.wander_initialized = false
   entity.wander_state = nil
   entity.wander_timer = nil
   entity.wander_target_x = nil
   entity.wander_target_y = nil
end

return Wander
