-- Chase primitive
-- Provides simple "move toward target" behavior
-- This is a stateless primitive - just calculates movement

local Chase = {}

--- Move entity toward a target position
--- @param entity EntityProxy The entity to move
--- @param target_x number Target X position
--- @param target_y number Target Y position
--- @param speed_mult number|nil Optional speed multiplier (default 1.0)
--- @return number dist The distance to target
function Chase.toward(entity, target_x, target_y, speed_mult)
   local dx = target_x - entity.x
   local dy = target_y - entity.y
   local dist = sqrt(dx * dx + dy * dy)
   local speed = entity.max_speed * (speed_mult or 1.0)

   if dist > 0 then
      entity.vel_x = (dx / dist) * speed
      entity.vel_y = (dy / dist) * speed
      entity.dir_x = sgn(dx)
      entity.dir_y = sgn(dy)
   end

   return dist
end

--- Move entity away from a target position (flee)
--- @param entity EntityProxy The entity to move
--- @param target_x number Target X position to flee from
--- @param target_y number Target Y position to flee from
--- @param speed_mult number|nil Optional speed multiplier (default 1.0)
--- @return number dist The distance to target
function Chase.away(entity, target_x, target_y, speed_mult)
   local dx = target_x - entity.x
   local dy = target_y - entity.y
   local dist = sqrt(dx * dx + dy * dy)
   local speed = entity.max_speed * (speed_mult or 1.0)

   if dist > 0 then
      entity.vel_x = -(dx / dist) * speed
      entity.vel_y = -(dy / dist) * speed
      entity.dir_x = sgn(dx) -- Face toward target even when fleeing
      entity.dir_y = sgn(dy)
   end

   return dist
end

--- Maintain a specific distance from target (orbit-like)
--- @param entity EntityProxy The entity to position
--- @param target_x number Target X position
--- @param target_y number Target Y position
--- @param ideal_dist number The ideal distance to maintain
--- @param tolerance number How much variance is acceptable
--- @return number dist The current distance to target
function Chase.maintain_distance(entity, target_x, target_y, ideal_dist, tolerance)
   local dx = target_x - entity.x
   local dy = target_y - entity.y
   local dist = sqrt(dx * dx + dy * dy)

   if dist > ideal_dist + tolerance then
      -- Too far, move closer
      Chase.toward(entity, target_x, target_y)
   elseif dist < ideal_dist - tolerance then
      -- Too close, back away
      Chase.away(entity, target_x, target_y, 1.5)
   else
      -- At ideal distance, slow down
      entity.vel_x = entity.vel_x * 0.9
      entity.vel_y = entity.vel_y * 0.9
   end

   -- Always face target
   if dist > 0 then
      entity.dir_x = sgn(dx)
      entity.dir_y = sgn(dy)
   end

   return dist
end

return Chase
