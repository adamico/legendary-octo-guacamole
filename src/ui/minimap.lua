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
local Events = require("src/game/events")

local Minimap = {}

-- State
Minimap.visited = {}           -- Hash map of visited room keys
Minimap.current_x = nil        -- Current X position
Minimap.current_y = nil        -- Current Y position
Minimap.target_x = nil         -- Target X position
Minimap.target_y = nil         -- Target Y position
Minimap.start_x = nil          -- Start X for tween
Minimap.start_y = nil          -- Start Y for tween
Minimap.quadrant = 0           -- 0:TR, 1:BR, 2:BL, 3:TL
Minimap.tween_timer = 0        -- Tween progress timer
Minimap.player_in_zone = false -- Track if player is overlapping

--- Helper: Get target coordinates for a quadrant
function Minimap.get_quadrant_pos(q)
   local cfg = GameConstants.Minimap
   local cell_total = cfg.cell_size + cfg.padding
   local viewport_width = cfg.viewport_w * cell_total - cfg.padding
   local viewport_height = cfg.viewport_h * cell_total - cfg.padding

   local x, y
   if q == 0 then -- Top-Right
      x = SCREEN_WIDTH - cfg.margin_x - viewport_width
      y = cfg.margin_y
   elseif q == 1 then -- Bottom-Right
      x = SCREEN_WIDTH - cfg.margin_x - viewport_width
      y = SCREEN_HEIGHT - cfg.margin_y_bottom - viewport_height
   elseif q == 2 then -- Bottom-Left
      x = cfg.margin_x
      y = SCREEN_HEIGHT - cfg.margin_y_bottom - viewport_height
   elseif q == 3 then -- Top-Left
      x = cfg.margin_x
      y = cfg.margin_y
   end
   return x, y
end

--- Helper: Get rotation direction based on approach velocity
--- @param q number Current quadrant (0-3)
--- @param vx number velocity X
--- @param vy number velocity Y
--- @return integer 1 (CW) or -1 (ACW)
function Minimap.get_rotation_direction(q, vx, vy)
   -- Default to Clockwise (1)
   local dir = 1
   local abs_vx = abs(vx)
   local abs_vy = abs(vy)

   if q == 0 then                    -- Top-Right
      if abs_vx > abs_vy then
         if vx > 0 then dir = 1 end  -- From Left -> CW
      else
         if vy < 0 then dir = -1 end -- From Bottom (moving up) -> ACW
      end
   elseif q == 1 then                -- Bottom-Right
      if abs_vy > abs_vx then
         if vy > 0 then dir = 1 end  -- From Top (moving down) -> CW
      else
         if vx > 0 then dir = -1 end -- From Left -> ACW
      end
   elseif q == 2 then                -- Bottom-Left
      if abs_vx > abs_vy then
         if vx < 0 then dir = 1 end  -- From Right -> CW
      else
         if vy > 0 then dir = -1 end -- From Top -> ACW
      end
   elseif q == 3 then                -- Top-Left
      if abs_vy > abs_vx then
         if vy < 0 then dir = 1 end  -- From Bottom -> CW
      else
         if vx < 0 then dir = -1 end -- From Right -> ACW
      end
   end
   return dir
end

--- Reset minimap state (call when entering play scene)
function Minimap.init()
   local cfg = GameConstants.Minimap

   Minimap.visited = {}
   Minimap.quadrant = 0 -- Start at Top-Right

   local start_x, start_y = Minimap.get_quadrant_pos(0)
   Minimap.current_x = start_x
   Minimap.current_y = start_y
   Minimap.target_x = start_x
   Minimap.target_y = start_y
   Minimap.start_x = start_x
   Minimap.start_y = start_y
   Minimap.tween_timer = 0
   Minimap.player_in_zone = false

   -- Subscribe to zone events
   Events.on(Events.MINIMAP_ZONE_ENTER, function(dir)
      -- Move to next quadrant based on direction (default CW)
      local d = dir or 1
      Minimap.quadrant = (Minimap.quadrant + d + 4) % 4
      Minimap.start_x = Minimap.current_x
      Minimap.start_y = Minimap.current_y
      Minimap.target_x, Minimap.target_y = Minimap.get_quadrant_pos(Minimap.quadrant)
      Minimap.tween_timer = cfg.tween_duration
   end)

   Events.on(Events.MINIMAP_ZONE_EXIT, function()
      -- Do nothing on exit; we stay in the new safe corner
   end)
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
--- @param map_y Y position of the minimap (top-left corner)
--- @return number screen_x, number screen_y, boolean is_visible
function Minimap.grid_to_screen_viewport(gx, gy, view_min_gx, view_min_gy, viewport_width, map_x, map_y)
   local cfg = GameConstants.Minimap
   local cell_total = cfg.cell_size + cfg.padding

   -- Position relative to viewport's top-left
   local rel_x = gx - view_min_gx
   local rel_y = gy - view_min_gy

   -- Check if within viewport bounds
   local is_visible = rel_x >= 0 and rel_x < cfg.viewport_w and
      rel_y >= 0 and rel_y < cfg.viewport_h

   local screen_x = map_x + rel_x * cell_total
   local screen_y = map_y + rel_y * cell_total

   return screen_x, screen_y, is_visible
end

--- Check if player screen position overlaps with minimap bounds (with margin)
--- @param player_screen_x Player X position in screen coordinates
--- @param player_screen_y Player Y position in screen coordinates
--- @param map_x Minimap X position
--- @param map_y Minimap Y position
--- @param viewport_width Minimap width
--- @param viewport_height Minimap height
--- @return boolean
function Minimap.is_player_overlapping(player_screen_x, player_screen_y, map_x, map_y, viewport_width, viewport_height)
   local cfg = GameConstants.Minimap
   local margin_x = cfg.overlap_margin_x or 16
   local margin_y = cfg.overlap_margin_y or 16

   -- Expand minimap bounds by margin for earlier detection
   local left = map_x - margin_x
   local right = map_x + viewport_width + margin_x
   local top = map_y - margin_y
   local bottom = map_y + viewport_height + margin_y

   -- Check if player center is within expanded minimap bounds
   return player_screen_x >= left and player_screen_x <= right and
      player_screen_y >= top and player_screen_y <= bottom
end

--- Update tween animation (call once per frame)
function Minimap.update()
   if Minimap.tween_timer > 0 then
      local cfg = GameConstants.Minimap
      -- Calculate progress (0 to 1, from end to start because timer counts down)
      local progress = 1 - (Minimap.tween_timer / cfg.tween_duration)
      -- Ease-out: fast start, slow end
      local eased = 1 - (1 - progress) * (1 - progress)

      -- Interpolate X and Y
      Minimap.current_x = Minimap.start_x + (Minimap.target_x - Minimap.start_x) * eased
      Minimap.current_y = Minimap.start_y + (Minimap.target_y - Minimap.start_y) * eased

      Minimap.tween_timer = Minimap.tween_timer - 1
   else
      Minimap.current_x = Minimap.target_x
      Minimap.current_y = Minimap.target_y
   end
end

--- Draw the minimap
--- @param current_room The player's current room
function Minimap.draw(current_room)
   local cfg = GameConstants.Minimap

   -- Get grid bounds
   local min_gx, max_gx, min_gy, max_gy = Minimap.get_grid_bounds()

   -- Calculate viewport bounds centered on current room
   local view_min_gx, view_min_gy = Minimap.get_viewport_bounds(current_room, min_gx, max_gx, min_gy, max_gy)

   -- Calculate viewport size in pixels
   local cell_total = cfg.cell_size + cfg.padding
   local viewport_width = cfg.viewport_w * cell_total - cfg.padding
   local viewport_height = cfg.viewport_h * cell_total - cfg.padding

   -- Calculate position using tweened current_y
   -- Calculate position using tweened current_x/y
   local map_x = Minimap.current_x or (SCREEN_WIDTH - cfg.margin_x - viewport_width)
   local map_y = Minimap.current_y or cfg.margin_y

   -- Draw checkerboard background (1px pattern: 0x5A5A)
   fillp(0x5A5A)
   rrectfill(map_x, map_y, viewport_width, viewport_height, 1, cfg.background_color)
   fillp(0) -- Reset fill pattern

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
               room.grid_x, room.grid_y, view_min_gx, view_min_gy, viewport_width, map_x, map_y)

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
            gx, gy, view_min_gx, view_min_gy, viewport_width, map_x, map_y)

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

--- Update minimap trigger logic (check player overlap)
--- @param player Player entity
--- @param camera_manager CameraManager instance
function Minimap.update_trigger(player, camera_manager)
   if not player then return end

   local cfg = GameConstants.Minimap
   local sx, sy = camera_manager:get_offset()
   local player_screen_x = player.x - sx + player.width / 2
   local player_screen_y = player.y - sy + player.height / 2

   local cell_total = cfg.cell_size + cfg.padding
   local viewport_width = cfg.viewport_w * cell_total - cfg.padding
   local viewport_height = cfg.viewport_h * cell_total - cfg.padding

   local map_x = Minimap.current_x or (SCREEN_WIDTH - cfg.margin_x - viewport_width)
   local map_y = Minimap.current_y or cfg.margin_y

   local is_overlapping = Minimap.is_player_overlapping(
      player_screen_x, player_screen_y, map_x, map_y, viewport_width, viewport_height)

   if is_overlapping and not Minimap.player_in_zone then
      Minimap.player_in_zone = true
      local dir = Minimap.get_rotation_direction(Minimap.quadrant, player.vel_x, player.vel_y)
      Events.emit(Events.MINIMAP_ZONE_ENTER, dir)
   elseif not is_overlapping and Minimap.player_in_zone then
      Minimap.player_in_zone = false
      Events.emit(Events.MINIMAP_ZONE_EXIT)
   end
end

return Minimap
