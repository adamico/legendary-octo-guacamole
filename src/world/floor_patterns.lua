-- Floor Pattern System
-- Provides tile selection patterns for room floors
-- Currently uses random as default, prepared for future patterns

local FloorPatterns = {}

-- Pattern registry
local Patterns = {}

--- Default random pattern (current behavior)
-- @param tx Tile X position
-- @param ty Tile Y position
-- @param tiles Table of floor tile options
-- @return Selected tile number
Patterns.random = function(tx, ty, tiles)
   return tiles[flr(rnd(#tiles)) + 1]
end

--- Get a floor pattern function by name
-- @param name Pattern name
-- @return Pattern function or random as fallback
function FloorPatterns.get_pattern(name)
   return Patterns[name] or Patterns.random
end

--- Get a floor tile using a pattern
-- @param pattern_name Pattern name string
-- @param tx Tile X position
-- @param ty Tile Y position
-- @param tiles Table of floor tile options (default: FLOOR_TILES)
-- @return Selected tile number
function FloorPatterns.get_tile(pattern_name, tx, ty, tiles)
   tiles = tiles or FLOOR_TILES
   local pattern = FloorPatterns.get_pattern(pattern_name)
   return pattern(tx, ty, tiles)
end

-- Future patterns can be added here:
-- Patterns.checkerboard = function(tx, ty, tiles) ... end
-- Patterns.border = function(tx, ty, tiles, bounds) ... end
-- Patterns.gradient = function(tx, ty, tiles, center) ... end

return FloorPatterns
