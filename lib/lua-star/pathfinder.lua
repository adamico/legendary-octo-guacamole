-- Pathfinding wrapper for Pizak
-- Provides tile-based pathfinding using lua-star
-- Integrates with DungeonManager for walkability checks
-- OPTIMIZED: Failed path cache, reduced search margin

local luastar = require("lib/lua-star/lua-star")

local Pathfinder = {}

-- Constants
local GRID_SIZE = 16 -- Tile size in pixels
local MAP_W = 256    -- Map width in tiles (extended map)
local MAP_H = 256    -- Map height in tiles (extended map)

-- Cache for the current room's walkability (cleared on room transition)
local walkability_cache = {}
local cache_room_key = nil

-- OPTIMIZATION: Cache failed pathfinding attempts (tile coords -> expiry time)
-- This prevents repeated expensive A* calls for unreachable destinations
local failed_path_cache = {}
local FAILED_CACHE_TTL = 5.0 -- Seconds before retrying a failed path - INCREASED from 2

--- Clear the walkability cache (call on room transitions)
function Pathfinder.clear_cache()
   walkability_cache = {}
   failed_path_cache = {} -- Also clear failed cache on room change
   cache_room_key = nil
   luastar:clearCached()
end

--- Check if a tile is walkable
--- @param tx number Tile X
--- @param ty number Tile Y
--- @param room table|nil Optional room for obstacle checks
--- @return boolean
function Pathfinder.is_walkable(tx, ty, room)
   -- Bounds check
   if tx < 0 or tx >= MAP_W or ty < 0 or ty >= MAP_H then
      return false
   end

   -- Check cache first
   local key = tx..","..ty
   if walkability_cache[key] ~= nil then
      return walkability_cache[key]
   end

   -- Query the map tile
   local tile = mget(tx, ty)

   -- Check if solid via sprite flag (flag 0 = solid)
   if fget(tile, SOLID_FLAG) then
      walkability_cache[key] = false
      return false
   end

   -- Check for pit tiles
   if tile == PIT_TILE then
      walkability_cache[key] = false
      return false
   end

   -- Check floor tiles
   local is_floor = false
   if tile == 0 or tile == EMPTY_TILE then
      is_floor = true
   else
      for _, f in ipairs(FLOOR_TILES) do
         if tile == f then
            is_floor = true
            break
         end
      end
   end

   if not is_floor then
      walkability_cache[key] = false
      return false
   end

   -- Check for dynamic obstacles (rocks, destructibles) in room
   if room and room.obstacle_entities then
      for _, obs in ipairs(room.obstacle_entities) do
         if not obs.destroyed then
            -- Check if this tile contains an obstacle by comparing tile coordinates
            local obs_tx = flr(obs.x / GRID_SIZE)
            local obs_ty = flr(obs.y / GRID_SIZE)
            -- Also check +1 tile in each direction for larger obstacles
            if tx == obs_tx and ty == obs_ty then
               walkability_cache[key] = false
               return false
            end
            -- Check if obstacle spans multiple tiles (use hitbox if available)
            local obs_w = obs.width or GRID_SIZE
            local obs_h = obs.height or GRID_SIZE
            local obs_tx2 = flr((obs.x + obs_w - 1) / GRID_SIZE)
            local obs_ty2 = flr((obs.y + obs_h - 1) / GRID_SIZE)
            if tx >= obs_tx and tx <= obs_tx2 and ty >= obs_ty and ty <= obs_ty2 then
               walkability_cache[key] = false
               return false
            end
         end
      end
   end

   walkability_cache[key] = true
   return true
end

--- Convert pixel coordinates to tile coordinates
--- @param px number Pixel X
--- @param py number Pixel Y
--- @return number, number Tile X, Tile Y
function Pathfinder.pixel_to_tile(px, py)
   return flr(px / GRID_SIZE), flr(py / GRID_SIZE)
end

--- Convert tile coordinates to pixel coordinates (center of tile)
--- @param tx number Tile X
--- @param ty number Tile Y
--- @return number, number Pixel X, Pixel Y (center)
function Pathfinder.tile_to_pixel(tx, ty)
   return tx * GRID_SIZE + GRID_SIZE / 2, ty * GRID_SIZE + GRID_SIZE / 2
end

--- Try to nudge a position to a nearby walkable tile
--- @param tx number Tile X
--- @param ty number Tile Y
--- @param room table|nil Optional room for obstacle checks
--- @return number|nil, number|nil Nudged tile coordinates, or nil if none found
local function nudge_to_walkable(tx, ty, room)
   for dy = -1, 1 do
      for dx = -1, 1 do
         if Pathfinder.is_walkable(tx + dx, ty + dy, room) then
            return tx + dx, ty + dy
         end
      end
   end
   return nil, nil
end

--- Find a path from start to goal (pixel coordinates)
--- @param start_x number Start pixel X
--- @param start_y number Start pixel Y
--- @param goal_x number Goal pixel X
--- @param goal_y number Goal pixel Y
--- @param room table|nil Optional room for obstacle checks
--- @return table|false Path as list of {x, y} pixel waypoints, or false if no path
function Pathfinder.find_path(start_x, start_y, goal_x, goal_y, room)
   local sx, sy = Pathfinder.pixel_to_tile(start_x, start_y)
   local gx, gy = Pathfinder.pixel_to_tile(goal_x, goal_y)

   -- Quick check: if start is unwalkable, try to nudge
   if not Pathfinder.is_walkable(sx, sy, room) then
      local nsx, nsy = nudge_to_walkable(sx, sy, room)
      if nsx then
         sx, sy = nsx, nsy
      else
         return false -- No valid start found
      end
   end

   -- Quick check: if goal is unwalkable, try to nudge
   if not Pathfinder.is_walkable(gx, gy, room) then
      local ngx, ngy = nudge_to_walkable(gx, gy, room)
      if ngx then
         gx, gy = ngx, ngy
      else
         return false -- No valid goal found
      end
   end

   -- Same tile? No path needed
   if sx == gx and sy == gy then
      return {}
   end

   -- OPTIMIZATION: Check failed path cache before expensive A* call
   local cache_key = sx..","..sy..">"..gx..","..gy
   local cached_failure = failed_path_cache[cache_key]
   if cached_failure and cached_failure > t() then
      return false -- Still within TTL, skip pathfinding
   end

   -- Calculate bounded search area (only search tiles near start/goal)
   -- Balance: larger margin finds more paths, smaller is faster
   local SEARCH_MARGIN = 12
   local min_x = min(sx, gx) - SEARCH_MARGIN
   local max_x = max(sx, gx) + SEARCH_MARGIN
   local min_y = min(sy, gy) - SEARCH_MARGIN
   local max_y = max(sy, gy) + SEARCH_MARGIN

   -- Create callback for lua-star with bounded checking
   local function is_open(x, y)
      -- Quick bounds check first
      if x < min_x or x > max_x or y < min_y or y > max_y then
         return false
      end
      return Pathfinder.is_walkable(x, y, room)
   end

   -- Find path in tile space (no diagonals for grid-aligned movement)
   -- Use bounded search area instead of full map
   local tile_path = luastar:find(
      max_x + 1, max_y + 1, -- Use max bounds as effective map size
      {x = sx, y = sy},
      {x = gx, y = gy},
      is_open,
      false, -- No caching (dynamic obstacles)
      true   -- Exclude diagonal movement
   )

   if not tile_path then
      -- OPTIMIZATION: Cache failed attempt to avoid retrying too soon
      failed_path_cache[cache_key] = t() + FAILED_CACHE_TTL
      return false
   end

   -- Convert to pixel waypoints (center of each tile)
   local pixel_path = {}
   for i, node in ipairs(tile_path) do
      -- Skip first waypoint if it's the current position
      if i > 1 then
         local px, py = Pathfinder.tile_to_pixel(node.x, node.y)
         add(pixel_path, {x = px, y = py})
      end
   end

   return pixel_path
end

return Pathfinder
