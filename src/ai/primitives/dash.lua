-- Dash primitive
-- Provides dash behavior: windup (aiming) and charge (rapid movement)
local EntityUtils = require("src/utils/entity_utils")

local Dash = {}

--- Handle windup phase: aim at target
--- @param entity table The dasher entity
--- @param dx number X distance to target
--- @param dy number Y distance to target
--- @param dist number Total distance to target
--- @param lock_aim boolean If true, do not update aim direction (aim is locked)
function Dash.windup(entity, dx, dy, dist, lock_aim)
   -- Stop moving during windup
   entity.vel_x = 0
   entity.vel_y = 0

   -- Update aim if target exists and aim is not locked
   if dist > 0 and not lock_aim then
      entity.dash_target_dx = dx / dist
      entity.dash_target_dy = dy / dist

      -- Update facing direction to match target so animation rotates correctly
      entity.dir_x = sgn(entity.dash_target_dx)
      entity.dir_y = sgn(entity.dash_target_dy)

      -- Force update current_direction for animation system (since vel is 0)
      entity.current_direction = EntityUtils.get_direction_name(
         entity.dash_target_dx,
         entity.dash_target_dy,
         entity.current_direction
      )

      return true -- Aim updated
   end

   return false -- Aim not updated (locked or no target)
end

--- Handle dash movement
--- @param entity table The dasher entity
--- @return boolean True if hit wall
function Dash.update(entity)
   -- Move at dash speed in cached direction
   local speed_mult = entity.dash_speed_multiplier or 4
   local dash_speed = entity.max_speed * speed_mult

   entity.vel_x = entity.dash_target_dx * dash_speed
   entity.vel_y = entity.dash_target_dy * dash_speed
   entity.dir_x = sgn(entity.dash_target_dx)
   entity.dir_y = sgn(entity.dash_target_dy)

   -- Return true if wall collision occurred
   if entity.hit_wall then
      entity.hit_wall = false
      return true
   end

   return false
end

return Dash
