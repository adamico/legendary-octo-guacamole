-- Dasher enemy AI profile
-- FSM: patrol -> windup -> dash -> stun -> puzzled -> patrol
-- Self-contained (doesn't use wander/chase primitives due to unique movement)

local machine = require("lib/lua-state-machine/statemachine")
local EntityUtils = require("src/utils/entity_utils")
local Emotions = require("src/systems/emotions")

local PUZZLED_DURATION = 60 -- frames to stay puzzled before patrol

-- Cardinal directions for patrol: {dx, dy}
local CARDINAL_DIRS = {
   {0,  -1}, -- up
   {0,  1},  -- down
   {-1, 0},  -- left
   {1,  0},  -- right
}

-- Get orthogonal directions to current direction
local function get_orthogonal_directions(dx, dy)
   if dx == 0 then
      -- Currently moving vertically, return horizontal options
      return {{-1, 0}, {1, 0}}
   else
      -- Currently moving horizontally, return vertical options
      return {{0, -1}, {0, 1}}
   end
end

-- Check if current patrol direction points toward the player
local function is_facing_player(entity, player)
   local dx = player.x - entity.x
   local dy = player.y - entity.y

   -- Check if patrol direction aligns with player direction
   if entity.patrol_dir_x ~= 0 then
      -- Moving horizontally
      return (entity.patrol_dir_x > 0 and dx > 0) or (entity.patrol_dir_x < 0 and dx < 0)
   else
      -- Moving vertically
      return (entity.patrol_dir_y > 0 and dy > 0) or (entity.patrol_dir_y < 0 and dy < 0)
   end
end

-- Initialize Dasher FSM on entity
local function init_fsm(entity)
   -- Pick initial random direction
   local initial_dir = CARDINAL_DIRS[flr(rnd(4)) + 1]
   entity.patrol_dir_x = initial_dir[1]
   entity.patrol_dir_y = initial_dir[2]

   entity.dasher_fsm = machine.create({
      initial = "patrol",
      events = {
         {name = "spot",    from = "patrol",  to = "windup"},  -- Player spotted, facing them
         {name = "charge",  from = "windup",  to = "dash"},    -- Windup complete
         {name = "collide", from = "dash",    to = "stun"},    -- Hit wall or player
         {name = "recover", from = "stun",    to = "puzzled"}, -- Stun timer finished
         {name = "wander",  from = "puzzled", to = "patrol"},  -- Puzzled timer finished
      },
      callbacks = {
         onenterwindup = function()
            Emotions.set(entity, "alert")
            entity.dasher_timer = entity.windup_duration
            entity.vel_x = 0
            entity.vel_y = 0
            if entity.fsm and entity.fsm:can("attack") then
               entity.fsm:attack()
            end
         end,
         onenterdash = function()
            entity.rotation_timer = 0
            entity.rotation_angle = 0
         end,
         onenterstun = function()
            Emotions.set(entity, "stunned")
            entity.dasher_timer = entity.stun_duration
            entity.vel_x = 0
            entity.vel_y = 0
            entity.dasher_collision = nil
            entity.rotation_angle = 0
         end,
         onenterpuzzled = function()
            Emotions.set(entity, "confused")
            entity.puzzled_timer = PUZZLED_DURATION
            entity.vel_x = 0
            entity.vel_y = 0
         end,
         onenterpatrol = function(self, event)
            if entity.fsm and entity.fsm:is("attacking") and entity.fsm:can("finish") then
               entity.fsm:finish()
            end

            local dir = CARDINAL_DIRS[flr(rnd(4)) + 1]
            entity.patrol_dir_x = dir[1]
            entity.patrol_dir_y = dir[2]
            entity.rotation_angle = 0
         end,
      }
   })
end

--- Main AI update for Dasher enemy type
-- @param entity The dasher entity
-- @param player The player entity (target)
local function dasher_ai(entity, player)
   -- Initialize FSM if needed
   if not entity.dasher_fsm then
      init_fsm(entity)
   end

   local fsm = entity.dasher_fsm

   -- Calculate distance to player (treat nil player as infinitely far)
   local in_range = false
   local dx, dy, dist = 0, 0, math.huge
   if player then
      dx = player.x - entity.x
      dy = player.y - entity.y
      dist = sqrt(dx * dx + dy * dy)
      in_range = dist <= entity.vision_range
   end

   -- State-specific behavior
   if fsm:is("patrol") then
      -- Check if blocked by wall last frame
      if entity.hit_wall then
         -- Pick a random orthogonal direction
         local ortho = get_orthogonal_directions(entity.patrol_dir_x, entity.patrol_dir_y)
         local choice = ortho[flr(rnd(2)) + 1]
         entity.patrol_dir_x = choice[1]
         entity.patrol_dir_y = choice[2]
         entity.hit_wall = false -- Clear flag
      end

      -- Move in patrol direction
      entity.vel_x = entity.patrol_dir_x * entity.max_speed
      entity.vel_y = entity.patrol_dir_y * entity.max_speed
      entity.dir_x = entity.patrol_dir_x ~= 0 and entity.patrol_dir_x or entity.dir_x
      entity.dir_y = entity.patrol_dir_y ~= 0 and entity.patrol_dir_y or entity.dir_y

      -- Transition: player in range AND facing toward them
      if in_range and is_facing_player(entity, player) then
         -- Cache the dash direction (normalized toward player)
         if dist > 0 then
            entity.dash_target_dx = dx / dist
            entity.dash_target_dy = dy / dist
         end
         fsm:spot()
      end
   elseif fsm:is("windup") then
      -- Stop moving during windup (already set by callback)
      entity.vel_x = 0
      entity.vel_y = 0

      -- Track player during windup so dash is accurate
      if dist > 0 then
         entity.dash_target_dx = dx / dist
         entity.dash_target_dy = dy / dist

         -- Update facing direction to match target so animation rotates correctly
         entity.dir_x = sgn(entity.dash_target_dx)
         entity.dir_y = sgn(entity.dash_target_dy)

         -- Force update current_direction for animation system (since vel is 0)
         entity.current_direction = EntityUtils.get_direction_name(entity.dash_target_dx, entity.dash_target_dy,
            entity.current_direction)
      end

      entity.dasher_timer = entity.dasher_timer - 1
      if entity.dasher_timer <= 0 then
         fsm:charge()
      end
   elseif fsm:is("dash") then
      -- Move at 4x speed in cached direction
      local dash_speed = entity.max_speed * entity.dash_speed_multiplier
      entity.vel_x = entity.dash_target_dx * dash_speed
      entity.vel_y = entity.dash_target_dy * dash_speed
      entity.dir_x = sgn(entity.dash_target_dx)
      entity.dir_y = sgn(entity.dash_target_dy)

      -- Rotate sprite
      entity.rotation_timer = (entity.rotation_timer or 0) + 1
      if entity.rotation_timer >= 8 then
         entity.rotation_timer = 0
         -- Rotate 90 degrees every 8 frames (always clockwise internally, flip_x handles visual direction)
         entity.rotation_angle = (entity.rotation_angle or 0) + 90
      end

      -- Transition: collision with wall (hit_wall) or player (dasher_collision)
      if entity.dasher_collision or entity.hit_wall then
         fsm:collide()
         entity.hit_wall = false -- Clear flag
      end
   elseif fsm:is("stun") then
      -- Stay idle (already set by callback)
      entity.vel_x = 0
      entity.vel_y = 0

      entity.dasher_timer = entity.dasher_timer - 1
      if entity.dasher_timer <= 0 then
         fsm:recover()
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

return dasher_ai
