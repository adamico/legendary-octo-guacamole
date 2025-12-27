-- Minimap Module
-- Isaac-style minimap displaying dungeon layout in the corner
--
-- Displays:
-- - Visited rooms as filled cells
-- - Current room with highlight (centered in viewport)
-- - Adjacent unvisited rooms (fog of war)
-- - Special room icons (start, shop, treasure, boss)
-- - Fixed viewport with scrolling when dungeon is larger

local DungeonManager = require("src/world/dungeon_manager")
local GameConstants = require("src/game/game_config")

local Minimap = {}

-- State
Minimap.visited = {} -- Hash map of visited room keys

--- Reset minimap state (call when entering play scene)
function Minimap.init()
   Minimap.visited = {}
end

--- Mark a room as visited
--- @param room The room to mark as visited
function Minimap.visit(room)
   if room then
      local key = room.grid_x..","..room.grid_y
      Minimap.visited[key] = true
   end
end

--- Check if a room has been visited
--- @param gx Grid X coordinate
--- @param gy Grid Y coordinate
--- @return boolean
function Minimap.is_visited(gx, gy)
   return Minimap.visited[gx..","..gy] == true
end

--- Calculate the grid bounds of all rooms
--- @return min_gx, max_gx, min_gy, max_gy
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

--- Calculate viewport offset to center on current room
--- @param current_room The player's current room
--- @param min_gx Minimum grid X
--- @param max_gx Maximum grid X
--- @param min_gy Minimum grid Y
--- @param max_gy Maximum grid Y
--- @return view_min_gx, view_min_gy (the grid coordinates of top-left cell in viewport)
function Minimap.get_viewport_bounds(current_room, min_gx, max_gx, min_gy, max_gy)
   local cfg = GameConstants.Minimap

   if not current_room then
      return min_gx, min_gy
   end

   -- Calculate the ideal top-left to center current room in viewport
   local half_vp_w = flr(cfg.viewport_w / 2)
   local half_vp_h = flr(cfg.viewport_h / 2)

   -- Always center on current room
   local view_min_gx = current_room.grid_x - half_vp_w
   local view_min_gy = current_room.grid_y - half_vp_h

   return view_min_gx, view_min_gy
end

--- Convert grid coordinates to screen position (with viewport bounds)
--- @param gx Grid X coordinate
--- @param gy Grid Y coordinate
--- @param view_min_gx Top-left grid X of viewport
--- @param view_min_gy Top-left grid Y of viewport
--- @param viewport_width Viewport width in pixels
--- @return screen_x, screen_y, is_visible
function Minimap.grid_to_screen_viewport(gx, gy, view_min_gx, view_min_gy, viewport_width)
   local cfg = GameConstants.Minimap
   local cell_total = cfg.cell_size + cfg.padding

   -- Position relative to viewport's top-left
   local rel_x = gx - view_min_gx
   local rel_y = gy - view_min_gy

   -- Check if within viewport bounds
   local is_visible = rel_x >= 0 and rel_x < cfg.viewport_w and
      rel_y >= 0 and rel_y < cfg.viewport_h

   -- Position from top-right corner of screen
   local base_x = SCREEN_WIDTH - cfg.margin_x - viewport_width
   local base_y = cfg.margin_y

   local screen_x = base_x + rel_x * cell_total
   local screen_y = base_y + rel_y * cell_total

   return screen_x, screen_y, is_visible
end

--- Draw the minimap
--- @param current_room The player's current room
function Minimap.draw(current_room)
   local cfg = GameConstants.Minimap

   -- Get grid bounds
   local min_gx, max_gx, min_gy, max_gy = Minimap.get_grid_bounds()
   local grid_w = max_gx - min_gx + 1
   local grid_h = max_gy - min_gy + 1

   -- Calculate viewport dimensions (clamped to actual dungeon size)
   local visible_w = min(cfg.viewport_w, grid_w)
   local visible_h = min(cfg.viewport_h, grid_h)

   -- Calculate viewport bounds centered on current room
   local view_min_gx, view_min_gy = Minimap.get_viewport_bounds(current_room, min_gx, max_gx, min_gy, max_gy)

   -- Calculate viewport size in pixels
   local cell_total = cfg.cell_size + cfg.padding
   local viewport_width = cfg.viewport_w * cell_total - cfg.padding
   local viewport_height = cfg.viewport_h * cell_total - cfg.padding

   -- Calculate top-left position of minimap
   local map_x = SCREEN_WIDTH - cfg.margin_x - viewport_width
   local map_y = cfg.margin_y

   -- Draw border around minimap viewport (for debugging positioning)
   rect(map_x - 1, map_y - 1, map_x + viewport_width, map_y + viewport_height, 8)

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
            local sx, sy, is_visible = Minimap.grid_to_screen_viewport(
               room.grid_x, room.grid_y, view_min_gx, view_min_gy, viewport_width)

            if is_visible then
               -- Draw filled cell for unexplored adjacent room
               rrectfill(sx, sy, cfg.cell_size, cfg.cell_size, 1, cfg.unexplored_color)

               -- Draw special room icon if applicable
               local icon = cfg.icons[room.room_type]
               if icon then
                  local icon_x = sx + flr((cfg.cell_size - cfg.icon_size) / 2)
                  local icon_y = sy + flr((cfg.cell_size - cfg.icon_size) / 2)
                  spr(icon, icon_x, icon_y)
               end
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
         local sx, sy, is_visible = Minimap.grid_to_screen_viewport(
            gx, gy, view_min_gx, view_min_gy, viewport_width)

         if is_visible then
            -- Determine if this is the current room
            local is_current = current_room and
               current_room.grid_x == gx and
               current_room.grid_y == gy

            -- Draw filled cell
            local fill_color = is_current and cfg.current_color or cfg.visited_color
            rrectfill(sx, sy, cfg.cell_size, cfg.cell_size, 1, fill_color)

            -- Draw special room icon
            local icon = cfg.icons[room.room_type]
            if icon then
               -- Center the 10x10 icon in the cell
               local icon_x = sx + flr((cfg.cell_size - cfg.icon_size) / 2)
               local icon_y = sy + flr((cfg.cell_size - cfg.icon_size) / 2)
               spr(icon, icon_x, icon_y)
            end
         end
      end
   end
end

return Minimap
