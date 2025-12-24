local Room = require("room")

-- Constants for procedural generation
local ROOM_TILES_W = 29 -- Fixed room width in tiles
local ROOM_TILES_H = 16 -- Fixed room height in tiles
local MIN_ENEMIES_PER_ROOM = 2
local MAX_ENEMIES_PER_ROOM = 5
local ENEMY_DENSITY_DIVISOR = 100   -- Tiles per enemy
local DEFAULT_ENEMY_MIN_DIST = 80   -- Minimum pixels from player
local MAP_MEMORY_ADDRESS = 0x100000 -- Picotron Extended Map Address
local EXT_MAP_W = 256               -- Large static world map
local EXT_MAP_H = 256               -- Large static world map
local GRID_STRIDE_X = ROOM_TILES_W  -- Rooms are directly adjacent (Isaac style)
local GRID_STRIDE_Y = ROOM_TILES_H  -- Rooms are directly adjacent (Isaac style)
local BASE_OFFSET_X = 64            -- Center offset for grid 0,0
local BASE_OFFSET_Y = 64            -- Center offset for grid 0,0
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
   DungeonManager.clear_map()
   for key, room in pairs(DungeonManager.rooms) do
      DungeonManager.carve_room(room)
      Log.trace("Room "..
         key.." at pixels ("..room.pixels.x..","..room.pixels.y..") size ("..room.pixels.w..","..room.pixels.h..")")
   end

   -- Phase 6: Carve corridors (after all rooms, so they pierce through margin walls)
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
         -- Blocked doors (sprite 6) are drawn manually with rotation,
         -- so we set the tile to 0 to avoid double-drawing
         if door.sprite == SPRITE_DOOR_BLOCKED then
            mset(pos.tx, pos.ty, 0)
         else
            mset(pos.tx, pos.ty, door.sprite)
         end
      end
   end
end

function DungeonManager.carve_corridors(room)
   if not room.doors then return end

   for dir, door in pairs(room.doors) do
      -- Get door position in current room
      local pos = room:get_door_tile(dir)
      if pos then
         -- Clear the door tile in current room
         mset(pos.tx, pos.ty, 0)

         -- Get adjacent room and clear its corresponding door tile
         local neighbor_key = door.target_gx..","..door.target_gy
         local neighbor = DungeonManager.rooms[neighbor_key]
         if neighbor then
            local opposite_dir = ({north = "south", south = "north", east = "west", west = "east"})[dir]
            local neighbor_pos = neighbor:get_door_tile(opposite_dir)
            if neighbor_pos then
               mset(neighbor_pos.tx, neighbor_pos.ty, 0)
            end
         end
      end
   end
end

function DungeonManager.carve_room(room, wall_options)
   wall_options = wall_options or {1, 2}

   -- Calculate margin needed for screen centering (tiles visible beyond room bounds)
   -- When room is smaller than screen, camera centers it, exposing tiles outside room.
   local room_px_w = room.tiles.w * GRID_SIZE
   local room_px_h = room.tiles.h * GRID_SIZE
   local margin_x = 0
   local margin_y = 0

   if room_px_w < SCREEN_WIDTH then
      local gap_x = (SCREEN_WIDTH - room_px_w) / 2
      margin_x = ceil(gap_x / GRID_SIZE)
   end
   if room_px_h < SCREEN_HEIGHT then
      local gap_y = (SCREEN_HEIGHT - room_px_h) / 2
      margin_y = ceil(gap_y / GRID_SIZE)
   end

   local bounds = room:get_bounds()

   -- Carve walls including margin area around the room
   for ty = bounds.y1 - margin_y, bounds.y2 + margin_y do
      for tx = bounds.x1 - margin_x, bounds.x2 + margin_x do
         -- Only carve if within extended map bounds
         if tx >= 0 and ty >= 0 and tx < EXT_MAP_W and ty < EXT_MAP_H then
            local sprite = wall_options[1]
            if #wall_options > 1 and rnd() < 0.1 then
               sprite = wall_options[flr(rnd(#wall_options - 1)) + 2]
            end
            mset(tx, ty, sprite)
         end
      end
   end

   -- Carve floor (inside walls)
   local floor = room:get_inner_bounds()
   for ty = floor.y1, floor.y2 do
      for tx = floor.x1, floor.x2 do
         mset(tx, ty, 0)
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
               sprite = SPRITE_DOOR_OPEN,
               target_gx = room.grid_x + d.dx,
               target_gy = room.grid_y + d.dy
            }
         end
      end
   end
end

function DungeonManager.clear_map()
   -- Clear the entire extended map
   for ty = 0, EXT_MAP_H - 1 do
      for tx = 0, EXT_MAP_W - 1 do
         mset(tx, ty, 0)
      end
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
