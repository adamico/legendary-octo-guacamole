local Room = require("room")
local Collision = require("collision")

local DungeonManager = {}

DungeonManager.current_room = nil
DungeonManager.rooms = {} -- Hash map: "x,y" -> Room
DungeonManager.current_grid_x = 0
DungeonManager.current_grid_y = 0

-- Constants for procedural generation
local MIN_ROOM_W = 10
local MAX_ROOM_W = 22
local MIN_ROOM_H = 8
local MAX_ROOM_H = 14
local MIN_ENEMIES_PER_ROOM = 2
local MAX_ENEMIES_PER_ROOM = 4
local ENEMY_DENSITY_DIVISOR = 100   -- Tiles per enemy
local DEFAULT_ENEMY_MIN_DIST = 80   -- Minimum pixels from player
local MAP_MEMORY_ADDRESS = 0x100000 -- Picotron Extended Map Address

-- Screen dimensions in tiles (visible area)
local SCREEN_TILES_W = 30 -- SCREEN_WIDTH / GRID_SIZE
local SCREEN_TILES_H = 16 -- Playable area height in tiles

-- Extended map dimensions (supports two max rooms in any direction)
local EXT_MAP_W = 80 -- MAX_ROOM_W * 2 + SCREEN_TILES_W + buffer
local EXT_MAP_H = 48 -- MAX_ROOM_H * 2 + SCREEN_TILES_H + buffer

-- Base offset for the "active view" - rooms carved relative to this
-- This gives us margin on all sides for previous room peek
local BASE_OFFSET_X = MAX_ROOM_W -- 22 tiles left margin
local BASE_OFFSET_Y = MAX_ROOM_H -- 14 tiles top margin

-- Legacy compatibility (used by create_room for centering)
local MAP_W = SCREEN_TILES_W
local MAP_H = SCREEN_TILES_H

-- The custom map userdata (initialized in init())
DungeonManager.map_data = nil

-- Procedural Generation Constants
local TARGET_ROOM_COUNT = 8
local DIRECTIONS = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}}

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

      -- Shuffle directions for variety
      local dirs = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}}
      local dir = dirs[flr(rnd(4)) + 1]
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

   -- Set initial state
   DungeonManager.current_grid_x = 0
   DungeonManager.current_grid_y = 0
   DungeonManager.current_room = start_room

   -- Carve initial room
   DungeonManager.clear_map()
   DungeonManager.carve_room(start_room)
   DungeonManager.carve_corridors(start_room)

   Log.info("Generated dungeon with "..#DungeonManager.get_all_rooms().." rooms")
end

function DungeonManager.create_room(gx, gy, is_safe)
   -- Random dimensions
   local w = flr(rnd(MAX_ROOM_W - MIN_ROOM_W + 1)) + MIN_ROOM_W
   local h = flr(rnd(MAX_ROOM_H - MIN_ROOM_H + 1)) + MIN_ROOM_H

   -- Force parity to match screen (Even Width 30, Even Height 16)
   w = w - (w % 2)
   h = h - (h % 2)

   -- Local position within a "virtual" screen cell
   local local_tx = flr((MAP_W - w) / 2)
   local local_ty = flr((MAP_H - h) / 2)

   -- Absolute World Position (Base Offset + Local)
   local world_tx = BASE_OFFSET_X + local_tx
   local world_ty = BASE_OFFSET_Y + local_ty

   local room = Room:new(world_tx, world_ty, w, h)

   -- Initialize state
   room.enemy_positions = {}
   room.spawn_timer = 60
   room.spawned = false
   room.is_safe = is_safe
   room.grid_x = gx
   room.grid_y = gy
   room.is_locked = false
   room.cleared = false

   return room
end

function DungeonManager.apply_door_sprites(room, tx_offset, ty_offset)
   if not room.doors then return end

   tx_offset = tx_offset or 0
   ty_offset = ty_offset or 0

   for dir, door in pairs(room.doors) do
      local pos = room:get_door_tile(dir)
      if pos then
         mset(pos.tx + tx_offset, pos.ty + ty_offset, door.sprite)
      end
   end
end

function DungeonManager.carve_corridors(room, tx_offset, ty_offset)
   if not room.doors then return end
   tx_offset = tx_offset or 0
   ty_offset = ty_offset or 0

   for dir, door in pairs(room.doors) do
      local pos = room:get_door_tile(dir)
      if pos then
         local dx, dy = DungeonManager.get_direction_delta(dir)
         for i = 1, CORRIDOR_LENGTH do
            local ctx = pos.tx + tx_offset + dx * i
            local cty = pos.ty + ty_offset + dy * i

            -- Place trigger in the middle of the corridor (i=2)
            local tile = (i == 2) and TRANSITION_TRIGGER_TILE or 0
            mset(ctx, cty, tile) -- Carve floor or trigger

            -- Carve walls around the corridor (1 tile width)
            if dx ~= 0 then
               mset(ctx, cty - 1, 1) -- Top wall
               mset(ctx, cty + 1, 1) -- Bottom wall
            else
               mset(ctx - 1, cty, 1) -- Left wall
               mset(ctx + 1, cty, 1) -- Right wall
            end
         end
      end
   end
end

function DungeonManager.carve_room(room, wall_options, tx_offset, ty_offset)
   wall_options = wall_options or {1, 2}
   tx_offset = tx_offset or 0
   ty_offset = ty_offset or 0

   local bounds = room:get_bounds()
   for ty = bounds.y1, bounds.y2 do
      for tx = bounds.x1, bounds.x2 do
         local sprite = wall_options[1]
         if #wall_options > 1 and rnd() < 0.1 then
            sprite = wall_options[flr(rnd(#wall_options - 1)) + 2]
         end
         mset(tx + tx_offset, ty + ty_offset, sprite)
      end
   end

   local floor = room:get_inner_bounds()
   for ty = floor.y1, floor.y2 do
      for tx = floor.x1, floor.x2 do
         mset(tx + tx_offset, ty + ty_offset, 0)
      end
   end

   DungeonManager.apply_door_sprites(room, tx_offset, ty_offset)
end

function DungeonManager.assign_enemies(room, num_enemies, min_dist, types)
   if room.is_safe then return end

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

function DungeonManager.enter_door(direction, skip_carve)
   local dx, dy = DungeonManager.get_direction_delta(direction)

   local target_gx = DungeonManager.current_grid_x + dx
   local target_gy = DungeonManager.current_grid_y + dy
   local key = target_gx..","..target_gy

   local next_room = DungeonManager.rooms[key]

   if next_room then
      DungeonManager.current_grid_x = target_gx
      DungeonManager.current_grid_y = target_gy
      DungeonManager.current_room = next_room

      -- Single-Screen transition: Clear previous room, carve new room
      if not skip_carve then
         DungeonManager.clear_map()
         DungeonManager.carve_room(next_room)
         DungeonManager.carve_corridors(next_room)
      end

      return next_room
   end
   return nil
end

function DungeonManager.init()
   DungeonManager.map_data = userdata("i16", EXT_MAP_W, EXT_MAP_H)
   memmap(DungeonManager.map_data, MAP_MEMORY_ADDRESS)
   DungeonManager.generate()
end

function DungeonManager.get_base_camera_offset()
   return {
      x = BASE_OFFSET_X * GRID_SIZE,
      y = BASE_OFFSET_Y * GRID_SIZE
   }
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
