-- Wave Pattern System with Positional DSL
-- Patterns are ASCII grids that map to room positions

local WavePatterns = {}

-- Enemy type legend (char → enemy type)
local ENEMY_LEGEND = {
   S = "Skulker",
   H = "Shooter",
   D = "Dasher"
}

-- Pattern definitions with difficulty ratings
local Patterns = {
   -- EASY (difficulty 1)
   skulker_pair = {
      difficulty = 1,
      grid = {
         ". . .",
         "S . S",
         ". . .",
      }
   },
   lone_shooter = {
      difficulty = 1,
      grid = {
         ". . .",
         ". H .",
         ". . .",
      }
   },
   skulker_line = {
      difficulty = 1,
      grid = {
         ". . . . .",
         ". S S S .",
         ". . . . .",
      }
   },

   -- MEDIUM (difficulty 2)
   ambush = {
      difficulty = 2,
      grid = {
         "S . . . S",
         ". . . . .",
         ". . H . .",
         ". . . . .",
         "S . . . S",
      }
   },
   flankers = {
      difficulty = 2,
      grid = {
         ". D . D .",
         ". . . . .",
         ". . . . .",
      }
   },
   shooter_guard = {
      difficulty = 2,
      grid = {
         ". . . . .",
         ". S . S .",
         ". . H . .",
         ". S . S .",
         ". . . . .",
      }
   },

   -- HARD (difficulty 3)
   chaos = {
      difficulty = 3,
      grid = {
         "S . S . S",
         ". . . . .",
         ". . D . .",
         ". . . . .",
         "H . . . H",
      }
   },
   dasher_wall = {
      difficulty = 3,
      grid = {
         ". . . . .",
         "D . D . D",
         ". . . . .",
         ". . H . .",
         ". . . . .",
      }
   },
   shooter_nest = {
      difficulty = 3,
      grid = {
         "H . . . H",
         ". . S . .",
         ". S . S .",
         ". . S . .",
         "H . . . H",
      }
   },
}

--- Parse a grid row into cells
-- @param row String like "S . . . S"
-- @return Table of characters
local function parse_row(row)
   local cells = {}
   for char in row:gmatch("%S") do
      add(cells, char)
   end
   return cells
end

--- Parse entire grid into 2D structure
-- @param grid Array of row strings
-- @return {rows, cols, cells}
local function parse_grid(grid)
   local rows = #grid
   local cells = {}
   local cols = 0

   for r, row_str in ipairs(grid) do
      cells[r] = parse_row(row_str)
      cols = max(cols, #cells[r])
   end

   return {rows = rows, cols = cols, cells = cells}
end

--- Calculate spawn positions from pattern grid
-- @param pattern Pattern definition with grid
-- @param bounds Room inner bounds {x1, y1, x2, y2} in tiles
-- @return Array of {x, y, type} in pixels
function WavePatterns.calculate_positions(pattern, bounds)
   if not pattern or not pattern.grid then return {} end

   local parsed = parse_grid(pattern.grid)
   local positions = {}

   -- Calculate room dimensions in pixels
   local room_x1 = bounds.x1 * GRID_SIZE
   local room_y1 = bounds.y1 * GRID_SIZE
   local room_w = (bounds.x2 - bounds.x1 + 1) * GRID_SIZE
   local room_h = (bounds.y2 - bounds.y1 + 1) * GRID_SIZE

   -- Cell size in room space
   local cell_w = room_w / parsed.cols
   local cell_h = room_h / parsed.rows

   -- Iterate grid and map to room positions
   for r = 1, parsed.rows do
      for c = 1, parsed.cols do
         local char = parsed.cells[r] and parsed.cells[r][c]
         local enemy_type = ENEMY_LEGEND[char]

         if enemy_type then
            -- Center of cell in room coordinates
            local x = room_x1 + (c - 0.5) * cell_w - 8 -- Offset by half sprite size
            local y = room_y1 + (r - 0.5) * cell_h - 8
            add(positions, {x = x, y = y, type = enemy_type})
         end
      end
   end

   return positions
end

--- Get all patterns at a specific difficulty
-- @param difficulty 1-3
-- @return Array of pattern keys
function WavePatterns.get_patterns_for_difficulty(difficulty)
   local result = {}
   for name, pattern in pairs(Patterns) do
      if pattern.difficulty == difficulty then
         add(result, name)
      end
   end
   return result
end

--- Get a random pattern at a specific difficulty
-- @param difficulty 1-3
-- @return Pattern definition or nil
function WavePatterns.get_random_pattern(difficulty)
   local candidates = WavePatterns.get_patterns_for_difficulty(difficulty)
   if #candidates == 0 then
      -- Fallback to lower difficulty
      if difficulty > 1 then
         return WavePatterns.get_random_pattern(difficulty - 1)
      end
      return nil
   end

   local name = candidates[flr(rnd(#candidates)) + 1]
   local pattern = Patterns[name]
   pattern.name = name -- Attach name for logging
   return pattern
end

--- Get a specific pattern by name
-- @param name Pattern name
-- @return Pattern definition or nil
function WavePatterns.get_pattern(name)
   return Patterns[name]
end

return WavePatterns
