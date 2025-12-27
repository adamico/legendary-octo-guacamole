-- Minimap Module
-- Isaac-style minimap displaying dungeon layout in the corner
--
-- Displays:
-- - Visited rooms as filled cells
-- - Current room with highlight
-- - Adjacent unvisited rooms (fog of war)
-- - Special room icons (start, shop, treasure, boss)

local DungeonManager = require("src/world/dungeon_manager")

local Minimap = {}

-- Configuration
Minimap.config = {
   cell_size = 11,       -- Size of each room cell in pixels (10x10 sprite + padding)
   padding = 1,          -- Padding between cells
   margin_x = 10,        -- Distance from right screen edge
   margin_y = 10,        -- Distance from top screen edge
   border_color = 5,     -- Dark gray for borders
   visited_color = 6,    -- Light gray for visited rooms
   current_color = 7,    -- White for current room
   unexplored_color = 1, -- Dark blue for unexplored but discovered (adjacent to visited)
   icon_size = 10,       -- Special room icon sprite size
}

-- Special room sprites (10x10)
Minimap.icons = {
   start = 192,
   shop = 193,
   treasure = 194,
   boss = 195,
}

-- State
Minimap.visited = {} -- Hash map of visited room keys

--- Reset minimap state (call when entering play scene)
function Minimap.init()
   Minimap.visited = {}
end

--- Mark a room as visited
-- @param room The room to mark as visited
function Minimap.visit(room)
   if room then
      local key = room.grid_x..","..room.grid_y
      Minimap.visited[key] = true
   end
end

--- Check if a room has been visited
-- @param gx Grid X coordinate
-- @param gy Grid Y coordinate
-- @return boolean
function Minimap.is_visited(gx, gy)
   return Minimap.visited[gx..","..gy] == true
end

--- Calculate the grid bounds of all rooms
-- @return min_gx, max_gx, min_gy, max_gy
function Minimap.get_grid_bounds()
   local min_gx, max_gx = 0, 0
   local min_gy, max_gy = 0, 0

   for _, room in pairs(DungeonManager.rooms) do
      min_gx = min(min_gx, room.grid_x)
      max_gx = max(max_gx, room.grid_x)
      min_gy = min(min_gy, room.grid_y)
      max_gy = max(max_gy, room.grid_y)
   end

   return min_gx, max_gx, min_gy, max_gy
end

--- Convert grid coordinates to screen position
-- @param gx Grid X coordinate
-- @param gy Grid Y coordinate
-- @param min_gx Minimum grid X (for offset calculation)
-- @param min_gy Minimum grid Y (for offset calculation)
-- @param map_width Total minimap width in pixels
-- @return screen_x, screen_y
function Minimap.grid_to_screen(gx, gy, min_gx, min_gy, map_width)
   local cfg = Minimap.config
   local cell_total = cfg.cell_size + cfg.padding

   -- Position from top-right corner
   local base_x = SCREEN_WIDTH - cfg.margin_x - map_width
   local base_y = cfg.margin_y

   local screen_x = base_x + (gx - min_gx) * cell_total
   local screen_y = base_y + (gy - min_gy) * cell_total

   return screen_x, screen_y
end

--- Draw the minimap
-- @param current_room The player's current room
function Minimap.draw(current_room)
   local cfg = Minimap.config

   -- Get grid bounds
   local min_gx, max_gx, min_gy, max_gy = Minimap.get_grid_bounds()
   local grid_w = max_gx - min_gx + 1
   local grid_h = max_gy - min_gy + 1

   -- Calculate total minimap size
   local cell_total = cfg.cell_size + cfg.padding
   local map_width = grid_w * cell_total - cfg.padding

   -- First pass: draw unexplored but adjacent rooms (fog of war)
   for _, room in pairs(DungeonManager.rooms) do
      local key = room.grid_x..","..room.grid_y
      if not Minimap.visited[key] then
         -- Check if adjacent to any visited room
         local is_adjacent = false
         if room.doors then
            for _, door in pairs(room.doors) do
               if Minimap.is_visited(door.target_gx, door.target_gy) then
                  is_adjacent = true
                  break
               end
            end
         end

         if is_adjacent then
            local sx, sy = Minimap.grid_to_screen(room.grid_x, room.grid_y, min_gx, min_gy, map_width)
            -- Draw filled cell for unexplored adjacent room
            rrectfill(sx, sy, cfg.cell_size, cfg.cell_size, 1, cfg.unexplored_color)

            -- Draw special room icon if applicable
            local icon = Minimap.icons[room.room_type]
            if icon then
               local icon_x = sx + flr((cfg.cell_size - cfg.icon_size) / 2)
               local icon_y = sy + flr((cfg.cell_size - cfg.icon_size) / 2)
               spr(icon, icon_x, icon_y)
            end
         end
      end
   end

   -- Second pass: draw visited rooms
   for key, _ in pairs(Minimap.visited) do
      -- Parse grid coordinates from key
      local gx, gy = key:match("(-?%d+),(-?%d+)")
      gx, gy = tonumber(gx), tonumber(gy)

      local room = DungeonManager.rooms[key]
      if room then
         local sx, sy = Minimap.grid_to_screen(gx, gy, min_gx, min_gy, map_width)

         -- Determine if this is the current room
         local is_current = current_room and
            current_room.grid_x == gx and
            current_room.grid_y == gy

         -- Draw filled cell
         local fill_color = is_current and cfg.current_color or cfg.visited_color
         rrectfill(sx, sy, cfg.cell_size, cfg.cell_size, 1, fill_color)

         -- -- Draw border for current room
         -- if is_current then
         --    rrect(sx - 1, sy - 1, cfg.cell_size, cfg.cell_size, 1, cfg.border_color)
         -- end

         -- Draw special room icon
         local icon = Minimap.icons[room.room_type]
         if icon then
            -- Center the 10x10 icon in the cell
            local icon_x = sx + flr((cfg.cell_size - cfg.icon_size) / 2)
            local icon_y = sy + flr((cfg.cell_size - cfg.icon_size) / 2)
            spr(icon, icon_x, icon_y)
         end
      end
   end
end

return Minimap
