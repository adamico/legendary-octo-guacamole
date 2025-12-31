--[[
    lua-star - A* path finding for Lua
    Copyright 2018 Wesley Werner <wesley.werner@gmail.com>
    HEAVILY OPTIMIZED for Picotron performance
]] --

local module = {}

-- OPTIMIZATION: Maximum nodes to explore before giving up (balanced for performance vs capability)
local MAX_NODES = 500 -- Increased from 300 to handle heavily obstructed rooms

-- Track explored nodes for debugging
local last_explored_count = 0
function module:getLastExploredCount()
   return last_explored_count
end

--- Clears all cached paths.
function module:clearCached()
   module.cache = nil
end

-- (Internal) Generate hash key for a tile coordinate
local function nodeKey(x, y)
   return x * 10000 + y
end

-- (Internal) Return the distance between two points (squared for performance).
local function distance(x1, y1, x2, y2)
   local dx = x1 - x2
   local dy = y1 - y2
   return dx * dx + dy * dy
end

-- (Internal) Clamp a value to a range.
local function clamp(x, min_val, max_val)
   return x < min_val and min_val or (x > max_val and max_val or x)
end

-- (Internal) Insert node into sorted list (maintains order, avoids full resort)
local function insertSorted(list, node)
   -- List is sorted high score to low (so we pop lowest from end)
   local score = node.score
   local pos = #list + 1
   for i = 1, #list do
      if list[i].score < score then
         pos = i
         break
      end
   end
   table.insert(list, pos, node)
end

-- (Internal) Requests adjacent map values around the given node.
local function getAdjacent(width, height, node, positionIsOpenFunc)
   local result = {}
   local nx, ny = node.x, node.y

   -- Cardinal directions only (no diagonals) - inline for speed
   local px, py

   -- Top
   py = ny - 1
   if py >= 1 and positionIsOpenFunc(nx, py) then
      result[#result + 1] = {x = nx, y = py}
   end

   -- Left
   px = nx - 1
   if px >= 1 and positionIsOpenFunc(px, ny) then
      result[#result + 1] = {x = px, y = ny}
   end

   -- Bottom
   py = ny + 1
   if py <= height and positionIsOpenFunc(nx, py) then
      result[#result + 1] = {x = nx, y = py}
   end

   -- Right
   px = nx + 1
   if px <= width and positionIsOpenFunc(px, ny) then
      result[#result + 1] = {x = px, y = ny}
   end

   return result
end

-- Returns the path from start to goal, or false if no path exists.
function module:find(width, height, start, goal, positionIsOpenFunc, useCache, excludeDiagonalMoving)
   local open = {}
   local nodes_explored = 0

   -- Hash tables for O(1) lookups
   local closed_hash = {}
   local open_hash = {}

   -- Initialize start node
   local start_H = distance(start.x, start.y, goal.x, goal.y)
   start.score = start_H
   start.G = 0
   start.parent = nil

   open[1] = start
   open_hash[nodeKey(start.x, start.y)] = start

   local goal_key = nodeKey(goal.x, goal.y)

   while #open > 0 do
      nodes_explored = nodes_explored + 1
      if nodes_explored > MAX_NODES then
         last_explored_count = nodes_explored
         return false
      end

      -- Pop lowest score node (at end of list)
      local current = table.remove(open)
      local current_key = nodeKey(current.x, current.y)

      open_hash[current_key] = nil
      closed_hash[current_key] = current

      -- Goal reached?
      if current_key == goal_key then
         -- Build path by traversing parents
         local path = {}
         local node = current
         while node do
            path[#path + 1] = {x = node.x, y = node.y}
            node = node.parent
         end
         -- Reverse path
         local reversed = {}
         for i = #path, 1, -1 do
            reversed[#reversed + 1] = path[i]
         end
         return reversed
      end

      -- Process adjacent cells
      local adjacentList = getAdjacent(width, height, current, positionIsOpenFunc)

      for i = 1, #adjacentList do
         local adjacent = adjacentList[i]
         local adj_key = nodeKey(adjacent.x, adjacent.y)

         if not closed_hash[adj_key] and not open_hash[adj_key] then
            local G = current.G + 1
            local H = distance(adjacent.x, adjacent.y, goal.x, goal.y)
            adjacent.score = G + H
            adjacent.G = G
            adjacent.parent = current

            insertSorted(open, adjacent)
            open_hash[adj_key] = adjacent
         end
      end
   end

   return false
end

return module
