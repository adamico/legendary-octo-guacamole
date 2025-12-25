local Room = require("room")

-- Constants for procedural generation
local ROOM_TILES_W = 29 -- Fixed room width in tiles
local ROOM_TILES_H = 16 -- Fixed room height in tiles (256px fits in 270px screen)
local MIN_ENEMIES_PER_ROOM = 2
local MAX_ENEMIES_PER_ROOM = 5
local ENEMY_DENSITY_DIVISOR = 100      -- Tiles per enemy
local DEFAULT_ENEMY_MIN_DIST = 80      -- Minimum pixels from player
local MAP_MEMORY_ADDRESS = 0x100000    -- Picotron Extended Map Address
local EXT_MAP_W = 256                  -- Large static world map
local EXT_MAP_H = 256                  -- Large static world map
local GRID_STRIDE_X = ROOM_TILES_W - 1 -- Rooms overlap by 1 tile (shared wall)
local GRID_STRIDE_Y = ROOM_TILES_H - 1 -- Rooms overlap by 1 tile (shared wall)
local BASE_OFFSET_X = 64               -- Center offset for grid 0,0
local BASE_OFFSET_Y = 64               -- Center offset for grid 0,0
local TARGET_ROOM_COUNT = 8
local DIRECTIONS = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}}

local DungeonManager = {}

DungeonManager.current_room = nil
DungeonManager.rooms = {} -- Hash map: "x,y" -> Room
DungeonManager.current_grid_x = 0
DungeonManager.current_grid_y = 0
DungeonManager.map_data = nil

-- Helper: Count neighbors at a grid position
function DungeonManager.count_neighbors(gx, gy)
   local count = 0
   for _, d in ipairs(DIRECTIONS) do
      if DungeonManager.rooms[(gx + d[1])..","..(gy + d[2])] then
         count += 1
      end
   end
   return count
end

-- Helper: Check if a room has no valid expansion directions
function DungeonManager.is_surrounded(gx, gy)
   return DungeonManager.count_neighbors(gx, gy) >= 4
      or DungeonManager.count_valid_expansion_dirs(gx, gy) == 0
end

-- Helper: Count directions where a new room could be placed (Rule of One)
function DungeonManager.count_valid_expansion_dirs(gx, gy)
   local count = 0
   for _, d in ipairs(DIRECTIONS) do
      local nx, ny = gx + d[1], gy + d[2]
      local key = nx..","..ny
      if not DungeonManager.rooms[key] and DungeonManager.count_neighbors(nx, ny) == 1 then
         count += 1
      end
   end
   return count
end

-- Helper: Get all rooms as a list
function DungeonManager.get_all_rooms()
   local list = {}
   for _, r in pairs(DungeonManager.rooms) do add(list, r) end
   return list
end

function DungeonManager.generate()
   DungeonManager.rooms = {}
   local active_list = {}

   -- Phase 1: Create Start Room at 0,0 (Safe Zone)
   local start_room = DungeonManager.create_room(0, 0, true)
   start_room.room_type = "start"
   DungeonManager.rooms["0,0"] = start_room
   add(active_list, start_room)

   -- Phase 2: Expansion Loop (Random Walk with Rule of One)
   while #DungeonManager.get_all_rooms() < TARGET_ROOM_COUNT and #active_list > 0 do
      -- Pick random room from active list
      local parent = active_list[flr(rnd(#active_list)) + 1]

      -- Pick random direction from constant
      local dir = DIRECTIONS[flr(rnd(#DIRECTIONS)) + 1]
      local nx, ny = parent.grid_x + dir[1], parent.grid_y + dir[2]
      local key = nx..","..ny

      -- Check: empty AND only 1 neighbor (Rule of One prevents 2x2 clusters)
      if not DungeonManager.rooms[key] then
         local neighbors = DungeonManager.count_neighbors(nx, ny)
         if neighbors == 1 then
            local new_room = DungeonManager.create_room(nx, ny, false)
            DungeonManager.rooms[key] = new_room
            add(active_list, new_room)
         end
      end

      -- Remove exhausted rooms (no valid expansion directions left)
      if DungeonManager.is_surrounded(parent.grid_x, parent.grid_y) then
         del(active_list, parent)
      end
   end

   -- Phase 3: Specialization (assign room types based on distance/topology)
   DungeonManager.assign_room_types()

   -- Phase 4: Connection (Connect Neighbor Rooms with corridor)
   DungeonManager.connect_neighbor_rooms()

   -- Phase 5: Carve entire dungeon into map
   DungeonManager.fill_map_with_walls() -- Fill entire map with walls first
   -- Carve floors for all rooms (clears inner bounds)
   for _, room in pairs(DungeonManager.rooms) do
      DungeonManager.carve_room_floor(room)
   end

   -- Phase 6: Apply autotiling to walls (corners, H/V variants)
   DungeonManager.autotile_walls()

   -- Phase 7: Carve corridors (opens door passages with frame tiles)
   for _, room in pairs(DungeonManager.rooms) do
      DungeonManager.carve_corridors(room)
   end

   -- Set initial state
   DungeonManager.current_grid_x = 0
   DungeonManager.current_grid_y = 0
   DungeonManager.current_room = start_room

   Log.info("Generated dungeon with "..#DungeonManager.get_all_rooms().." rooms")
end

function DungeonManager.create_room(gx, gy, is_safe)
   -- Fixed room dimensions (Isaac style - fills screen)
   local w = ROOM_TILES_W
   local h = ROOM_TILES_H

   -- Grid-based absolute position (rooms directly adjacent)
   local world_tx = BASE_OFFSET_X + (gx * GRID_STRIDE_X)
   local world_ty = BASE_OFFSET_Y + (gy * GRID_STRIDE_Y)

   local room = Room:new(world_tx, world_ty, w, h, is_safe)

   -- Initialize room metadata
   room.grid_x = gx
   room.grid_y = gy

   return room
end

function DungeonManager.apply_door_sprites(room)
   if not room.doors then return end

   for dir, door in pairs(room.doors) do
      local pos = room:get_door_tile(dir)
      if pos then
         mset(pos.tx, pos.ty, door.sprite)
      end
   end
end

function DungeonManager.carve_corridors(room)
   if not room.doors then return end

   for dir, door in pairs(room.doors) do
      -- Get door position in current room
      local pos = room:get_door_tile(dir)
      if pos then
         -- Set door tile to 0 (transparent) - actual door sprite drawn by rendering
         mset(pos.tx, pos.ty, 0)

         -- Place door frame tiles based on direction
         if dir == "north" or dir == "south" then
            -- North/South door: frame on left and right
            local left_tile = DOOR_FRAME_V_LEFT[flr(rnd(#DOOR_FRAME_V_LEFT)) + 1]
            local right_tile = DOOR_FRAME_V_RIGHT[flr(rnd(#DOOR_FRAME_V_RIGHT)) + 1]
            mset(pos.tx - 1, pos.ty, left_tile)
            mset(pos.tx + 1, pos.ty, right_tile)
         else
            -- East/West door: frame on top and bottom
            local top_tile = DOOR_FRAME_H_TOP[flr(rnd(#DOOR_FRAME_H_TOP)) + 1]
            local bottom_tile = DOOR_FRAME_H_BOTTOM[flr(rnd(#DOOR_FRAME_H_BOTTOM)) + 1]
            mset(pos.tx, pos.ty - 1, top_tile)
            mset(pos.tx, pos.ty + 1, bottom_tile)
         end
      end
   end
end

function DungeonManager.carve_room_floor(room)
   local floor = room:get_inner_bounds()
   for ty = floor.y1, floor.y2 do
      for tx = floor.x1, floor.x2 do
         -- Use random floor tile variant
         local floor_tile = FLOOR_TILES[flr(rnd(#FLOOR_TILES)) + 1]
         mset(tx, ty, floor_tile)
      end
   end

   DungeonManager.apply_door_sprites(room)
end

function DungeonManager.assign_enemies(room, num_enemies, min_dist, types)
   local area = room.tiles.w * room.tiles.h
   local default_count = mid(MIN_ENEMIES_PER_ROOM, flr(area / ENEMY_DENSITY_DIVISOR), MAX_ENEMIES_PER_ROOM)

   room.contents_config = room.contents_config or {}
   room.contents_config.enemies = {
      count = num_enemies or default_count,
      min_dist = min_dist or DEFAULT_ENEMY_MIN_DIST,
      types = types
   }
end

-- Phase 3: Assign room types based on distance and topology
function DungeonManager.assign_room_types()
   -- Calculate Manhattan distance from origin for each room
   for _, room in pairs(DungeonManager.rooms) do
      room.distance = abs(room.grid_x) + abs(room.grid_y)
   end

   -- Find leaf nodes (1 neighbor only, excluding start)
   local leaves = {}
   for _, room in pairs(DungeonManager.rooms) do
      if room.room_type ~= "start" then
         local neighbors = DungeonManager.count_neighbors(room.grid_x, room.grid_y)
         if neighbors == 1 then
            add(leaves, room)
         end
      end
   end

   -- Sort leaves by distance (descending) - farthest first
   for i = 1, #leaves - 1 do
      for j = i + 1, #leaves do
         if leaves[j].distance > leaves[i].distance then
            leaves[i], leaves[j] = leaves[j], leaves[i]
         end
      end
   end

   -- Assign special types: farthest = boss, next = treasure, next = shop
   if #leaves >= 1 then
      leaves[1].room_type = "boss"
      leaves[1].floor_color = 8 -- Red tint
   end
   if #leaves >= 2 then
      leaves[2].room_type = "treasure"
      leaves[2].floor_color = 12 -- Cyan
   end
   if #leaves >= 3 then
      leaves[3].room_type = "shop"
      leaves[3].floor_color = 10 -- Yellow
   end

   -- Remaining rooms are combat rooms with enemies
   local combat_enemy_types = {"Skulker", "Skulker", "Shooter", "Dasher"} -- Weighted toward Skulker
   for _, room in pairs(DungeonManager.rooms) do
      if not room.room_type then
         room.room_type = "combat"
         room.floor_color = 5 -- Default gray
         DungeonManager.assign_enemies(room, nil, nil, combat_enemy_types)
      end
   end
end

-- Phase 4: Connect neighbor rooms and setup corridors
function DungeonManager.connect_neighbor_rooms()
   local door_dirs = {
      {dx = 1,  dy = 0,  from = "east",  to = "west"},
      {dx = -1, dy = 0,  from = "west",  to = "east"},
      {dx = 0,  dy = -1, from = "north", to = "south"},
      {dx = 0,  dy = 1,  from = "south", to = "north"}
   }

   for _, room in pairs(DungeonManager.rooms) do
      room.doors = room.doors or {}
      for _, d in ipairs(door_dirs) do
         local neighbor_key = (room.grid_x + d.dx)..","..(room.grid_y + d.dy)
         if DungeonManager.rooms[neighbor_key] then
            room.doors[d.from] = {
               sprite = DOOR_OPEN_TILE,
               target_gx = room.grid_x + d.dx,
               target_gy = room.grid_y + d.dy
            }
         end
      end
   end
end

function DungeonManager.fill_map_with_walls()
   -- Fill entire extended map with wall tiles
   for ty = 0, EXT_MAP_H - 1 do
      for tx = 0, EXT_MAP_W - 1 do
         mset(tx, ty, WALL_TILE)
      end
   end
end

-- Helper: Check if a tile is a floor tile
function DungeonManager.is_floor_tile(tx, ty)
   local tile = mget(tx, ty)
   if tile == 0 then return true end
   for _, f in ipairs(FLOOR_TILES) do
      if tile == f then return true end
   end
   return false
end

-- Apply contextual autotiling to walls based on adjacent floor tiles
-- OPTIMIZED: Only processes wall tiles around room perimeters instead of entire 256x256 map
function DungeonManager.autotile_walls()
   -- Build a set of wall tiles to process (perimeter of each room + 1 tile margin)
   local tiles_to_check = {}
   local visited = {}

   for _, room in pairs(DungeonManager.rooms) do
      local floor = room:get_inner_bounds()
      -- Check the wall ring around the floor (1 tile margin on all sides)
      local x1, y1 = floor.x1 - 1, floor.y1 - 1
      local x2, y2 = floor.x2 + 1, floor.y2 + 1

      for ty = y1, y2 do
         for tx = x1, x2 do
            -- Only add wall tiles (skip interior floor tiles)
            local is_interior = tx >= floor.x1 and tx <= floor.x2 and ty >= floor.y1 and ty <= floor.y2
            if not is_interior then
               local key = tx..","..ty
               if not visited[key] then
                  visited[key] = true
                  add(tiles_to_check, {tx = tx, ty = ty})
               end
            end
         end
      end
   end

   -- Process only the collected wall tiles
   for _, tile in ipairs(tiles_to_check) do
      local tx, ty = tile.tx, tile.ty

      -- Skip if somehow became a floor tile
      if DungeonManager.is_floor_tile(tx, ty) then goto continue end

      -- Check orthogonally adjacent tiles for floor
      local floor_above          = DungeonManager.is_floor_tile(tx, ty - 1)
      local floor_below          = DungeonManager.is_floor_tile(tx, ty + 1)
      local floor_left           = DungeonManager.is_floor_tile(tx - 1, ty)
      local floor_right          = DungeonManager.is_floor_tile(tx + 1, ty)

      -- Check diagonally adjacent tiles for floor (for corners)
      local floor_diag_br        = DungeonManager.is_floor_tile(tx + 1, ty + 1)
      local floor_diag_bl        = DungeonManager.is_floor_tile(tx - 1, ty + 1)
      local floor_diag_tr        = DungeonManager.is_floor_tile(tx + 1, ty - 1)
      local floor_diag_tl        = DungeonManager.is_floor_tile(tx - 1, ty - 1)

      -- Count orthogonal floor neighbors
      local has_orthogonal_floor = floor_above or floor_below or floor_left or floor_right

      -- CORNER HANDLING: walls with no orthogonal floor neighbors
      if not has_orthogonal_floor then
         -- Count diagonal floor neighbors
         local diag_count = 0
         if floor_diag_tl then diag_count += 1 end
         if floor_diag_tr then diag_count += 1 end
         if floor_diag_bl then diag_count += 1 end
         if floor_diag_br then diag_count += 1 end

         if diag_count == 2 then
            -- 2 diagonal floors: check which pair to determine inner corner
            if floor_diag_tl and floor_diag_tr then
               -- Two on top: inner corner pointing down
               mset(tx, ty, WALL_TILE_INNER_TOP)
            elseif floor_diag_bl and floor_diag_br then
               -- Two on bottom: inner corner pointing up
               mset(tx, ty, WALL_TILE_INNER_BOTTOM)
            elseif floor_diag_tr and floor_diag_br then
               -- Two on right: inner corner pointing left
               mset(tx, ty, WALL_TILE_INNER_RIGHT)
            elseif floor_diag_tl and floor_diag_bl then
               -- Two on left: inner corner pointing right
               mset(tx, ty, WALL_TILE_INNER_LEFT)
            end
            -- Diagonal pair (TL+BR or TR+BL): leave as full wall (default)
         elseif diag_count == 1 then
            -- Single diagonal floor: outer corner (original logic)
            if floor_diag_br then
               mset(tx, ty, WALL_TILE_CORNER_TL) -- A: top-left corner (floor at bottom-right)
            elseif floor_diag_bl then
               mset(tx, ty, WALL_TILE_CORNER_TR) -- B: top-right corner (floor at bottom-left)
            elseif floor_diag_tr then
               mset(tx, ty, WALL_TILE_CORNER_BL) -- C: bottom-left corner (floor at top-right)
            elseif floor_diag_tl then
               mset(tx, ty, WALL_TILE_CORNER_BR) -- D: bottom-right corner (floor at top-left)
            end
         end
         -- diag_count == 0: leave as full wall (no adjacent floors)
      elseif floor_above or floor_below then
         -- Horizontal wall (floor above or below)
         local variants = WALL_TILE_HORIZONTAL
         mset(tx, ty, variants[flr(rnd(#variants)) + 1])
      elseif floor_left or floor_right then
         -- Vertical wall (floor left or right)
         local variants = WALL_TILE_VERTICAL
         mset(tx, ty, variants[flr(rnd(#variants)) + 1])
      end
      -- Otherwise: leave as full wall (Z) - no adjacent floors

      ::continue::
   end
end

function DungeonManager.enter_door(direction)
   local dx, dy = DungeonManager.get_direction_delta(direction)

   local target_gx = DungeonManager.current_grid_x + dx
   local target_gy = DungeonManager.current_grid_y + dy
   local key = target_gx..","..target_gy

   local next_room = DungeonManager.rooms[key]

   if next_room then
      DungeonManager.current_grid_x = target_gx
      DungeonManager.current_grid_y = target_gy
      DungeonManager.current_room = next_room

      return next_room
   end
   return nil
end

function DungeonManager.init()
   DungeonManager.map_data = userdata("i16", EXT_MAP_W, EXT_MAP_H)
   memmap(DungeonManager.map_data, MAP_MEMORY_ADDRESS)
   DungeonManager.generate()
end

-- Helper: Get vector delta for a direction string
function DungeonManager.get_direction_delta(direction)
   if direction == "east" then return 1, 0 end
   if direction == "west" then return -1, 0 end
   if direction == "north" then return 0, -1 end
   if direction == "south" then return 0, 1 end
   return 0, 0
end

-- Helper: Get direction string from vector delta
function DungeonManager.get_direction_name(dx, dy)
   if dx == 1 and dy == 0 then return "east" end
   if dx == -1 and dy == 0 then return "west" end
   if dx == 0 and dy == -1 then return "north" end
   if dx == 0 and dy == 1 then return "south" end
   return nil
end

-- Peek at next room without committing transition (for RoomManager scroll animation)
function DungeonManager.peek_next_room(direction)
   local dx, dy = DungeonManager.get_direction_delta(direction)

   local target_gx = DungeonManager.current_grid_x + dx
   local target_gy = DungeonManager.current_grid_y + dy
   local key = target_gx..","..target_gy

   return DungeonManager.rooms[key]
end

-- Calculate player spawn position for given door direction
-- Preserves Y for horizontal (east/west) and X for vertical (north/south) doors
-- Returns WORLD coordinates (absolute pixels)
function DungeonManager.calculate_spawn_position(direction, room, current_x, current_y)
   local x, y = 0, 0
   local p_w = GameConstants.Player.width
   local p_h = GameConstants.Player.height

   if direction == "east" then
      -- Moving East, entering next room from West
      -- Wall at x, Floor at x + GRID_SIZE. Player at x + GRID_SIZE (flush against wall)
      x = room.pixels.x + GRID_SIZE
      y = current_y
   elseif direction == "west" then
      -- Moving West, entering next room from East
      -- Wall starts at x+w-GRID_SIZE. Player right edge at x+w-GRID_SIZE.
      -- Player left edge at x+w-GRID_SIZE-p_w (flush against wall)
      x = room.pixels.x + room.pixels.w - GRID_SIZE - p_w
      y = current_y
   elseif direction == "north" then
      x = current_x
      -- Moving North, entering next room from South
      -- Wall at y+h-GRID_SIZE. Player bottom edge at y+h-GRID_SIZE.
      -- Player top edge at y+h-GRID_SIZE-p_h (flush against wall)
      y = room.pixels.y + room.pixels.h - GRID_SIZE - p_h
   elseif direction == "south" then
      -- Moving South, entering next room from North
      -- Wall at y, Floor at y+GRID_SIZE. Player at y+GRID_SIZE (flush against wall)
      x = current_x
      y = room.pixels.y + GRID_SIZE
   end

   return {x = x, y = y}
end

function DungeonManager.draw()
   if DungeonManager.current_room then
      DungeonManager.current_room:draw()
   end
end

return DungeonManager
