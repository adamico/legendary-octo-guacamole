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

-- Door Sprites
local SPRITE_DOOR_OPEN = 3
local SPRITE_DOOR_BLOCKED = 4

function DungeonManager.generate()
   DungeonManager.rooms = {}

   -- 1. Create Start Room at 0,0 (Safe Zone)
   local start_room = DungeonManager.create_room(0, 0, true)
   DungeonManager.rooms["0,0"] = start_room

   -- 2. Create Adjacent Room
   local next_room_x = 0
   local next_room_y = -1
   local next_room_xy = next_room_x..","..next_room_y
   local enemy_room = DungeonManager.create_room(next_room_x, next_room_y, false)
   DungeonManager.rooms[next_room_xy] = enemy_room

   -- 3. Connect them (Place Doors)
   -- East door for Start Room (Direction from Start to Next)
   local dir_to_next = DungeonManager.get_direction_name(next_room_x, next_room_y)
   assert(dir_to_next, "Failed to resolve direction to next room")

   start_room.doors = start_room.doors or {}
   start_room.doors[dir_to_next] = {
      sprite = SPRITE_DOOR_OPEN,
      target_gx = next_room_x,
      target_gy = next_room_y
   }

   -- West door for Enemy Room (Direction from Next to Start)
   local dir_to_start = DungeonManager.get_direction_name(-next_room_x, -next_room_y)
   assert(dir_to_start, "Failed to resolve direction to start room")

   enemy_room.doors = enemy_room.doors or {}
   enemy_room.doors[dir_to_start] = {sprite = SPRITE_DOOR_OPEN, target_gx = 0, target_gy = 0}

   -- Assign content to Enemy Room
   DungeonManager.assign_enemies(enemy_room, nil, 80)

   -- Set initial state
   DungeonManager.current_grid_x = 0
   DungeonManager.current_grid_y = 0
   DungeonManager.current_room = start_room

   -- Carve all rooms initially (or at least the current one)
   DungeonManager.clear_map()
   DungeonManager.carve_room(start_room)
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

function DungeonManager.update_door_sprites(room, tx_offset, ty_offset)
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

      -- Single-Screen transition: Clear previous room, carve new room
      DungeonManager.clear_map()
      DungeonManager.carve_room(next_room)

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
