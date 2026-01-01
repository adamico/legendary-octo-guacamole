-- PathFollow AI Primitive
-- Provides pathfinding-based movement toward a target
-- Uses A* via the Pathfinder wrapper
-- OPTIMIZED: Frame budget guard, extended staggering, increased direct move distance

local Pathfinder = require("lib/lua-star/pathfinder")
local EntityUtils = require("src/utils/entity_utils")
local HitboxUtils = require("src/utils/hitbox_utils")

local PathFollow = {}

-- Configuration
local REPATH_INTERVAL = 180    -- Frames between path recalculations (3 seconds) - INCREASED from 90
local WAYPOINT_RADIUS = 8      -- Distance to consider waypoint reached
local STUCK_THRESHOLD = 5      -- Frames without progress before re-pathing
local STUCK_DIST_THRESHOLD = 2 -- Minimum movement per frame to not be "stuck"
local DIRECT_MOVE_DIST = 80    -- Use direct movement if target within this distance (5 tiles) - INCREASED from 64
local MAX_PATH_LENGTH = 50     -- Increased from 30 to handle paths across large rooms
local MAX_PATHS_PER_FRAME = 1  -- Maximum A* calculations per frame (frame budget) - REDUCED from 2

-- Entity counter for staggering (distributes pathfinding across frames)
local entity_counter = 0

-- Frame budget tracking (reset each frame by calling reset_frame_budget)
local paths_this_frame = 0
local last_frame_time = 0

--- Reset the frame budget counter (call once per frame from main update)
function PathFollow.reset_frame_budget()
   paths_this_frame = 0
end

--- Check if there's a clear line-of-sight between two points (no solid tiles in the way)
--- Uses Bresenham-style stepping along the line
--- @param x1 number Start X (pixels)
--- @param y1 number Start Y (pixels)
--- @param x2 number End X (pixels)
--- @param y2 number End Y (pixels)
--- @param room table|nil Room for obstacle checks
--- @return boolean True if path is clear
local function has_line_of_sight(x1, y1, x2, y2, room)
   local dx = x2 - x1
   local dy = y2 - y1
   local dist = sqrt(dx * dx + dy * dy)
   if dist < 8 then return true end -- Very close, assume clear

   -- Step along the line in 8-pixel increments
   local steps = ceil(dist / 8)
   local step_x = dx / steps
   local step_y = dy / steps

   for i = 1, steps do
      local px = x1 + step_x * i
      local py = y1 + step_y * i
      local tx, ty = flr(px / 16), flr(py / 16)

      if not Pathfinder.is_walkable(tx, ty, room) then
         return false
      end
   end

   return true
end

--- Initialize pathfinding state on an entity
--- @param entity table Entity to initialize
local function init_path_state(entity)
   if not entity.path_state then
      -- Give each entity a unique stagger offset to distribute pathfinding
      -- OPTIMIZATION: Increased spread from 10 to 15 entities over 90 frames
      entity_counter = entity_counter + 1
      local stagger = (entity_counter % 15) * 6 -- Spread across ~90 frames (6 frames apart)

      entity.path_state = {
         path = nil,             -- Current path waypoints
         path_index = 1,         -- Current waypoint index
         repath_timer = stagger, -- Start staggered to avoid all pathing same frame
         target_x = nil,         -- Last known target position
         target_y = nil,
         last_x = nil,           -- Position last frame (stuck detection)
         last_y = nil,
         stuck_frames = 0,       -- Consecutive frames with no progress
      }
   end
end

--- Clear the current path (call when changing targets or states)
--- @param entity table Entity to clear path for
function PathFollow.clear_path(entity)
   if entity.path_state then
      entity.path_state.path = nil
      entity.path_state.path_index = 1
      entity.path_state.repath_timer = 0
      entity.path_state.stuck_frames = 0
   end
end

--- Check if entity has an active path
--- @param entity table Entity to check
--- @return boolean
function PathFollow.has_path(entity)
   return entity.path_state and entity.path_state.path and #entity.path_state.path > 0
end

--- Move entity toward a target using pathfinding
--- @param entity table Entity to move
--- @param target_x number Target pixel X
--- @param target_y number Target pixel Y
--- @param speed_mult number|nil Speed multiplier (default 1.0)
--- @param room table|nil Current room for obstacle awareness
--- @return number Distance to target
function PathFollow.toward(entity, target_x, target_y, speed_mult, room)
   init_path_state(entity)
   local state = entity.path_state
   local speed = entity.max_speed * (speed_mult or 1.0)

   -- Get entity center position
   local hb = HitboxUtils.get_hitbox(entity)
   local ex = hb.x + hb.w / 2
   local ey = hb.y + hb.h / 2

   -- Calculate distance to final target
   local dx = target_x - ex
   local dy = target_y - ey
   local dist_to_target = sqrt(dx * dx + dy * dy)

   -- Check if we need to recalculate path
   local need_repath = false

   -- Decrement repath timer
   state.repath_timer = max(0, state.repath_timer - 1)

   -- Reasons to repath:
   -- 1. No path exists
   if not state.path then
      need_repath = true
      -- 2. Timer expired
   elseif state.repath_timer <= 0 then
      need_repath = true
      -- 3. Target moved significantly (> 2 tiles)
   elseif state.target_x and state.target_y then
      local target_moved = abs(target_x - state.target_x) + abs(target_y - state.target_y)
      if target_moved > 32 then
         need_repath = true
      end
      -- 4. Entity is stuck
   elseif state.stuck_frames >= STUCK_THRESHOLD then
      need_repath = true
      state.stuck_frames = 0
   end

   -- Calculate new path if needed
   if need_repath then
      -- Skip pathfinding if target is close enough for direct movement
      if dist_to_target < DIRECT_MOVE_DIST then
         state.path = nil
         state.repath_timer = REPATH_INTERVAL
      else
         -- OPTIMIZATION: Frame budget guard - skip A* if budget exhausted
         if paths_this_frame < MAX_PATHS_PER_FRAME then
            paths_this_frame = paths_this_frame + 1
            local new_path = Pathfinder.find_path(ex, ey, target_x, target_y, room)
            -- Only use path if it's reasonably short
            if new_path and #new_path <= MAX_PATH_LENGTH then
               state.path = new_path
            else
               state.path = nil -- Too long or no path, use direct movement
            end
            state.path_index = 1
            state.target_x = target_x
            state.target_y = target_y
            state.repath_timer = REPATH_INTERVAL
         else
            -- Budget exhausted, delay repath by a few frames
            state.repath_timer = 3 + (entity_counter % 5) -- Staggered retry
         end
      end
   end

   -- Stuck detection: check if we moved since last frame
   if state.last_x and state.last_y then
      local moved = abs(ex - state.last_x) + abs(ey - state.last_y)
      if moved < STUCK_DIST_THRESHOLD then
         state.stuck_frames = state.stuck_frames + 1
      else
         state.stuck_frames = 0
      end
   end
   state.last_x = ex
   state.last_y = ey

   -- If no valid path, stop movement and let caller handle (e.g., wander, give up)
   -- Previously this fell back to direct movement, but that caused entities to walk
   -- into pits/walls when A* correctly determined no path exists
   if not state.path or #state.path == 0 then
      entity.vel_x = 0
      entity.vel_y = 0
      return dist_to_target
   end

   -- Get current waypoint
   local waypoint = state.path[state.path_index]
   if not waypoint then
      -- Reached end of path, clear it
      PathFollow.clear_path(entity)
      return dist_to_target
   end

   -- PATH SMOOTHING: Try to skip ahead to a further waypoint if we have line-of-sight
   -- Check waypoints from furthest to nearest, use the furthest one we can see
   local best_waypoint_idx = state.path_index
   for i = #state.path, state.path_index + 1, -1 do
      local future_wp = state.path[i]
      if has_line_of_sight(ex, ey, future_wp.x, future_wp.y, room) then
         best_waypoint_idx = i
         break -- Found furthest visible waypoint
      end
   end

   -- Also check if we can move directly to the final target
   if has_line_of_sight(ex, ey, target_x, target_y, room) then
      -- Direct path to target is clear! Skip all waypoints
      dx = target_x - ex
      dy = target_y - ey
      local direct_dist = sqrt(dx * dx + dy * dy)
      if direct_dist > 0 then
         entity.vel_x = (dx / direct_dist) * speed
         entity.vel_y = (dy / direct_dist) * speed
         entity.dir_x = sgn(dx)
         entity.dir_y = sgn(dy)
         entity.current_direction = EntityUtils.get_direction_name(dx, dy, entity.current_direction)
      end
      return dist_to_target
   end

   -- Update waypoint to the best (furthest visible) one
   if best_waypoint_idx > state.path_index then
      state.path_index = best_waypoint_idx
   end
   waypoint = state.path[state.path_index]

   -- Calculate direction to waypoint
   local wx = waypoint.x - ex
   local wy = waypoint.y - ey
   local dist_to_waypoint = sqrt(wx * wx + wy * wy)

   -- Check if waypoint reached
   if dist_to_waypoint < WAYPOINT_RADIUS then
      state.path_index = state.path_index + 1
      -- Check if path complete
      if state.path_index > #state.path then
         PathFollow.clear_path(entity)
         return dist_to_target
      end
      -- Move to next waypoint
      waypoint = state.path[state.path_index]
      wx = waypoint.x - ex
      wy = waypoint.y - ey
      dist_to_waypoint = sqrt(wx * wx + wy * wy)
   end

   -- Move toward current waypoint
   if dist_to_waypoint > 0 then
      entity.vel_x = (wx / dist_to_waypoint) * speed
      entity.vel_y = (wy / dist_to_waypoint) * speed
      entity.dir_x = sgn(wx)
      entity.dir_y = sgn(wy)
      entity.current_direction = EntityUtils.get_direction_name(wx, wy, entity.current_direction)
   end

   return dist_to_target
end

--- Debug: Draw the current path (call from rendering system)
--- @param entity table Entity with path
--- @param color number|nil Line color (default 11 = green)
function PathFollow.debug_draw(entity, color)
   if not entity.path_state or not entity.path_state.path then return end

   color = color or 11
   local path = entity.path_state.path
   local idx = entity.path_state.path_index or 1

   if #path == 0 or idx > #path then return end

   -- Draw line from entity to first waypoint
   local first_wp = path[idx]
   if first_wp then
      local ex = entity.x + (entity.width or 16) / 2
      local ey = entity.y + (entity.height or 16) / 2
      line(ex, ey, first_wp.x, first_wp.y, color)
   end

   -- Draw remaining path segments
   for i = idx, #path - 1 do
      local p1 = path[i]
      local p2 = path[i + 1]
      line(p1.x, p1.y, p2.x, p2.y, color)
   end

   -- Draw waypoints
   for i = idx, #path do
      local p = path[i]
      circfill(p.x, p.y, 2, color)
   end
end

-- Export line-of-sight check for external use (e.g., chick AI direct chase)
PathFollow.has_line_of_sight = has_line_of_sight

return PathFollow
