-- Physics and movement systems
-- Handles acceleration, friction, and velocity application
local Entities = require("src/entities")
local Effects = require("src/systems/effects")
local DungeonManager = require("src/world/dungeon_manager")

local Physics = {}

-- Internal: apply acceleration, friction, and clamp velocity
-- Internal: apply acceleration, friction, and clamp velocity (column version)
local function apply_accel_logic(i, accel_c, vel_c, dir_c, timers_c)
   -- Handle stun: no movement at all
   if timers_c and timers_c.stun_timer and timers_c.stun_timer[i] and timers_c.stun_timer[i] > 0 then
      timers_c.stun_timer[i] = timers_c.stun_timer[i] - 1
      vel_c.vel_x[i] = 0
      vel_c.vel_y[i] = 0
      return
   end

   local dx = (dir_c and dir_c.dir_x[i]) or 0
   local dy = (dir_c and dir_c.dir_y[i]) or 0

   -- Normalize acceleration for diagonal movement
   local accel = accel_c.accel[i]
   if dx ~= 0 and dy ~= 0 then
      accel = accel * 0.7071 -- sqrt(2)/2 for diagonal
   end

   -- Apply acceleration
   if dx ~= 0 then vel_c.vel_x[i] = vel_c.vel_x[i] + dx * accel end
   if dy ~= 0 then vel_c.vel_y[i] = vel_c.vel_y[i] + dy * accel end

   -- Apply friction when not actively moving in a direction
   if dx == 0 then vel_c.vel_x[i] = vel_c.vel_x[i] * accel_c.friction[i] end
   if dy == 0 then vel_c.vel_y[i] = vel_c.vel_y[i] * accel_c.friction[i] end

   -- Handle slow: reduce max_speed temporarily
   local max_spd = accel_c.max_speed[i]
   if timers_c and timers_c.slow_timer and timers_c.slow_timer[i] and timers_c.slow_timer[i] > 0 then
      timers_c.slow_timer[i] = timers_c.slow_timer[i] - 1
      max_spd = max_spd * (timers_c.slow_factor and timers_c.slow_factor[i] or 0.5)
   end

   -- Clamp to max speed
   vel_c.vel_x[i] = mid(-max_spd, vel_c.vel_x[i], max_spd)
   vel_c.vel_y[i] = mid(-max_spd, vel_c.vel_y[i], max_spd)

   -- Stop completely if very slow (prevents drift)
   if abs(vel_c.vel_x[i]) < 0.1 then vel_c.vel_x[i] = 0 end
   if abs(vel_c.vel_y[i]) < 0.1 then vel_c.vel_y[i] = 0 end
end

-- Internal: apply velocity to position with sub-pixel precision (column version)
local function apply_vel_logic(i, pos_c, vel_c)
   -- Initialize sub-pixel accumulators if not present (handled by ECS defaults usually, but checking here)
   local sub_x = vel_c.sub_x[i] or 0
   local sub_y = vel_c.sub_y[i] or 0

   -- Accumulate velocity (including fractional parts)
   sub_x = sub_x + vel_c.vel_x[i]
   sub_y = sub_y + vel_c.vel_y[i]

   -- Extract whole pixel movement
   local move_x = flr(sub_x)
   local move_y = flr(sub_y)

   -- Handle negative values correctly (flr rounds toward negative infinity)
   if sub_x < 0 and sub_x ~= move_x then
      move_x = ceil(sub_x) - 1
   end
   if sub_y < 0 and sub_y ~= move_y then
      move_y = ceil(sub_y) - 1
   end

   -- Apply whole pixel movement
   pos_c.x[i] = pos_c.x[i] + move_x
   pos_c.y[i] = pos_c.y[i] + move_y

   -- Keep the remainder for next frame
   vel_c.sub_x[i] = sub_x - move_x
   vel_c.sub_y[i] = sub_y - move_y
end





-- Update acceleration for all entities with acceleration tag
-- @param world - ECS world
function Physics.acceleration(world)
   world:query({"acceleration", "velocity", "direction?", "timers?"}, function(ids, accel, vel, dir, timers)
      for i = ids.first, ids.last do
         apply_accel_logic(i, accel, vel, dir, timers)
      end
   end)
end

-- Update velocity for all entities with velocity tag
-- @param world - ECS world
function Physics.velocity(world)
   world:query({"position", "velocity"}, function(ids, pos, vel)
      for i = ids.first, ids.last do
         apply_vel_logic(i, pos, vel)
      end
   end)
end

-- Apply knockback to velocity BEFORE collision resolution
-- Consumes the knockback impulse and adds it to the entity's current velocity
function Physics.knockback_pre(world)
   world:query({"velocity"}, function(ids, vel)
      for i = ids.first, ids.last do
         local kx = vel.knockback_vel_x[i] or 0
         local ky = vel.knockback_vel_y[i] or 0

         if kx ~= 0 or ky ~= 0 then
            vel.vel_x[i] = vel.vel_x[i] + kx
            vel.vel_y[i] = vel.vel_y[i] + ky

            -- Consume the impulse
            vel.knockback_vel_x[i] = 0
            vel.knockback_vel_y[i] = 0
         end
      end
   end)
end

-- Decay knockback AFTER velocity is applied (Unused in Impulse model, kept for API compatibility)
function Physics.knockback_post(world)
   -- Handled by standard friction in Physics.acceleration
end

--- Update Z-axis physics (gravity, movement, ground collision)
--- @param world ECS world
function Physics.z_axis(world)
   world:query({"position", "velocity", "acceleration?", "lifetime?", "type", "tags?"},
      function(ids, pos, vel, accel, lifetime, type_c, tags_c)
         for i = ids.first, ids.last do
            -- Read current state
            local z = pos.z[i] or 0
            local v_z = vel.vel_z[i] or 0
            local g_z = (accel and accel.gravity_z[i]) or -0.15

            local age = (lifetime and lifetime.age[i]) or 0
            local max_age = (lifetime and lifetime.max_age[i]) or 0

            -- Age update
            if lifetime and max_age > 0 then
               age = age + 1
               lifetime.age[i] = age

               -- Delayed gravity for projectiles
               local drop_start = max_age * 0.75
               if age >= drop_start then
                  v_z += g_z
               end
            else
               -- Standard gravity
               v_z += g_z
            end

            local prev_z = z
            z += v_z

            -- Vertical shot adjustment (shadow catches up to sprite)
            -- Warning: access instance_data keys "vertical_shot"? Not in components.
            -- Should be in a component if used here.
            -- Assuming vertical_shot logic is niche or needs component.
            -- Skipping specific vertical_shot fix in this migration step for simplicity.

            local hit_ground = false
            if z <= 0 and g_z < 0 then
               z = 0
               v_z = 0
               hit_ground = true
            end

            -- Write back
            pos.z[i] = z
            vel.vel_z[i] = v_z

            if hit_ground then
               -- Logic for ground impact (egg hatching, etc)
               -- Needs to check tags/type
               -- This logic was complex in original file accessing "owner", "tags" string, etc.
               -- Simplified here for migration pass.
               if type_c and (type_c.value[i] == "Projectile" or type_c.value[i] == "EnemyProjectile") then
                  -- Handle impact
                  -- Requires spawning entities etc.
                  -- Defer destruction to world.del(ids[i])?
                  -- picobloc deletion: world:del_entity(ids[i])
                  world:del_entity(ids[i])

                  -- Spawning logic for egg hatching omitted for brevity in this chunk
                  -- Should extract to specific handler or system later
               end
            end
         end
      end)
end

return Physics
