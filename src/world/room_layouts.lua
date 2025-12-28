-- Room Layout System with ASCII DSL
-- Layouts define interior patterns of rooms (obstacles, pits, rocks)
-- Data is loaded from data/room_layout_data.lua
--
-- GRID SYSTEM:
-- - 9×7 grid maps to 27×14 room interior (each cell = 3×2 tiles)
-- - cell_pattern array specifies how each feature instance is placed
-- - Features cycle through cell_pattern in reading order

local LayoutData = require("src/data/room_layout_data")

local RoomLayouts = {}

-- Import data
local FEATURE_LEGEND = LayoutData.FEATURE_LEGEND
local CELL_POSITIONS = LayoutData.CELL_POSITIONS
local Layouts = LayoutData.Layouts

-- Grid constants
local GRID_COLS = LayoutData.GRID_COLS or 9
local GRID_ROWS = LayoutData.GRID_ROWS or 7
local CELL_WIDTH = LayoutData.CELL_WIDTH or 3
local CELL_HEIGHT = LayoutData.CELL_HEIGHT or 2

-- Build LayoutsByRoomType dynamically from each layout's room_types field
local LayoutsByRoomType = {}
for name, layout in pairs(Layouts) do
   if layout.room_types then
      for _, room_type in ipairs(layout.room_types) do
         LayoutsByRoomType[room_type] = LayoutsByRoomType[room_type] or {}
         add(LayoutsByRoomType[room_type], name)
      end
   end
end

--- Parse a grid row into cells (no-space format: "R..R..R")
-- @param row String like "R..R..R.."
-- @return Table of characters
local function parse_row(row)
   local cells = {}
   for i = 1, #row do
      local char = row:sub(i, i)
      if char ~= " " then -- Skip spaces for backward compatibility
         add(cells, char)
      end
   end
   return cells
end

--- Parse entire grid into 2D structure (cached on layout)
-- @param layout Layout definition
-- @return {rows, cols, cells}
local function get_parsed_grid(layout)
   if not layout or not layout.grid then return nil end

   -- Return cached version if available
   if layout._parsed then return layout._parsed end

   local rows = #layout.grid
   local cells = {}
   local cols = 0

   for r, row_str in ipairs(layout.grid) do
      cells[r] = parse_row(row_str)
      cols = max(cols, #cells[r])
   end

   layout._parsed = {rows = rows, cols = cols, cells = cells}
   return layout._parsed
end

--- Check if a layout is valid for a room based on door requirements
-- @param layout_name Name of the layout
-- @param room Room object with doors table
-- @return true if layout can be used
local function is_layout_valid_for_room(layout_name, room)
   local layout = Layouts[layout_name]
   if not layout or not layout.requires_no_doors then return true end
   if not room or not room.doors then return true end

   -- Check if room has any of the forbidden doors
   for _, forbidden_dir in ipairs(layout.requires_no_doors) do
      if room.doors[forbidden_dir] then
         return false
      end
   end
   return true
end

--- Get a random layout for a room type
-- @param room_type "combat", "start", "boss", etc.
-- @param room Optional room object (for door-based filtering)
-- @return Layout definition
function RoomLayouts.get_random_layout(room_type, room)
   local all_candidates = LayoutsByRoomType[room_type] or LayoutsByRoomType.combat or {"open"}

   -- Filter by door requirements if room provided
   local candidates = {}
   for _, name in ipairs(all_candidates) do
      if is_layout_valid_for_room(name, room) then
         add(candidates, name)
      end
   end

   -- Fallback to open if no valid candidates
   if #candidates == 0 then
      candidates = {"open"}
   end

   local name = candidates[flr(rnd(#candidates)) + 1]
   local layout = Layouts[name]
   layout.name = name
   return layout
end

--- Get a specific layout by name
-- @param name Layout name
-- @return Layout definition or nil
function RoomLayouts.get_layout(name)
   return Layouts[name]
end

--- Get all features from a layout with their tile positions
-- Returns a list of {feature, tile_x, tile_y} for each feature tile
-- @param layout Layout definition
-- @param room_inner_x Room inner left edge in tiles (after wall)
-- @param room_inner_y Room inner top edge in tiles (after wall)
-- @return Array of {feature, tx, ty}
function RoomLayouts.get_all_features(layout, room_inner_x, room_inner_y)
   local parsed = get_parsed_grid(layout)
   if not parsed then return {} end

   local features = {}
   local cell_pattern = layout.cell_pattern
   local pattern_index = 1

   -- Iterate grid in reading order (top-to-bottom, left-to-right)
   for gy = 1, parsed.rows do
      for gx = 1, #parsed.cells[gy] do
         local char = parsed.cells[gy][gx]
         local feature_type = FEATURE_LEGEND[char]

         if feature_type and feature_type ~= "floor" then
            -- Get position mode for this feature
            local pos_mode = "f" -- default to full
            if cell_pattern then
               pos_mode = cell_pattern[pattern_index] or "f"
               pattern_index = pattern_index + 1
               if pattern_index > #cell_pattern then
                  pattern_index = 1 -- cycle
               end
            end

            -- Get position offset and size from mode
            local pos_data = CELL_POSITIONS[pos_mode] or CELL_POSITIONS.f
            local offset_x, offset_y, width, height = pos_data[1], pos_data[2], pos_data[3], pos_data[4]

            -- Calculate base tile position (0-indexed from room inner)
            local base_tx = (gx - 1) * CELL_WIDTH
            local base_ty = (gy - 1) * CELL_HEIGHT

            -- Add tiles based on width/height
            for dy = 0, height - 1 do
               for dx = 0, width - 1 do
                  local tx = room_inner_x + base_tx + offset_x + dx
                  local ty = room_inner_y + base_ty + offset_y + dy
                  add(features, {feature = feature_type, tx = tx, ty = ty})
               end
            end
         end
      end
   end

   return features
end

--- Get the feature at a specific tile position (for spawn validation)
-- @param layout Layout definition
-- @param gx Grid X position (0-indexed from room left inner)
-- @param gy Grid Y position (0-indexed from room top inner)
-- @param room_w Room inner width in tiles (should be 27)
-- @param room_h Room inner height in tiles (should be 14)
-- @return Feature type string or nil for floor
function RoomLayouts.get_feature_at(layout, gx, gy, room_w, room_h)
   local parsed = get_parsed_grid(layout)
   if not parsed then return nil end

   -- Map tile position to grid cell
   local grid_x = flr(gx / CELL_WIDTH) + 1
   local grid_y = flr(gy / CELL_HEIGHT) + 1

   -- Bounds check
   if grid_y < 1 or grid_y > parsed.rows then return nil end
   if grid_x < 1 or grid_x > #parsed.cells[grid_y] then return nil end

   local char = parsed.cells[grid_y][grid_x]
   local feature = FEATURE_LEGEND[char]

   if feature == "floor" then return nil end

   -- For simple check, assume feature fills the cell
   -- More precise checking would need to count features and apply cell_pattern
   return feature
end

--- Get tile for a feature type
-- @param feature Feature type string ("rock", "pit", "destructible")
-- @return Tile number
function RoomLayouts.get_feature_tile(feature)
   if feature == "rock" then
      return ROCK_TILES[flr(rnd(#ROCK_TILES)) + 1]
   elseif feature == "pit" then
      return PIT_TILE
   elseif feature == "destructible" then
      return DESTRUCTIBLE_TILES[flr(rnd(#DESTRUCTIBLE_TILES)) + 1]
   elseif feature == "wall" then
      return WALL_TILE
   end
   return nil
end

--- Check if a tile is a feature tile (rock, pit, or destructible)
-- @param tile Tile number
-- @return Feature type string or nil
function RoomLayouts.get_tile_feature_type(tile)
   -- Check rocks
   for _, t in ipairs(ROCK_TILES) do
      if tile == t then return "rock" end
   end
   -- Check pit
   if tile == PIT_TILE then return "pit" end
   -- Check destructibles
   for _, t in ipairs(DESTRUCTIBLE_TILES) do
      if tile == t then return "destructible" end
   end
   return nil
end

--- Check if a tile position is a floor tile (for spawn validation)
-- @param tx Tile X position
-- @param ty Tile Y position
-- @return true if floor tile
function RoomLayouts.is_floor_tile(tx, ty)
   local tile = mget(tx, ty)
   if tile == 0 then return false end
   for _, f in ipairs(FLOOR_TILES) do
      if tile == f then return true end
   end
   return false
end

return RoomLayouts
