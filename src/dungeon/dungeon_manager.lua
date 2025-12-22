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

local ROOM_DIRECTIONS = {
   ["1,0"] = "east",
   ["-1,0"] = "west",
   ["0,1"] = "south",
   ["0,-1"] = "north"
}

function DungeonManager.generate()
   DungeonManager.rooms = {}

   -- 1. Create Start Room at 0,0 (Safe Zone)
   local start_room = DungeonManager.create_room(0, 0, true)
   DungeonManager.rooms["0,0"] = start_room

   -- 2. Create Adjacent Room
   local next_room_x = 0
   local next_room_y = -1
   local next_room_xy = next_room_x..","..next_room_y
   local next_door_xy = -next_room_x..","..-next_room_y
   local enemy_room = DungeonManager.create_room(next_room_x, next_room_y, false)
   DungeonManager.rooms[next_room_xy] = enemy_room

   -- 3. Connect them (Place Doors)
   -- East door for Start Room
   start_room.doors = start_room.doors or {}
   start_room.doors[ROOM_DIRECTIONS[next_room_xy]] = {
      sprite = SPRITE_DOOR_OPEN,
      target_gx = next_room_x,
      target_gy = next_room_y
   }

   -- West door for Enemy Room
   enemy_room.doors = enemy_room.doors or {}
   enemy_room.doors[ROOM_DIRECTIONS[next_door_xy]] = {sprite = SPRITE_DOOR_OPEN, target_gx = 0, target_gy = 0}

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

   -- Fill room with walls (using absolute room tile coords + optional temp offset)
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

   -- Carve floor
   local floor = room:get_inner_bounds()
   for ty = floor.y1, floor.y2 do
      for tx = floor.x1, floor.x2 do
         mset(tx + tx_offset, ty + ty_offset, 0)
      end
   end

   -- Place Doors
   DungeonManager.apply_door_sprites(room, tx_offset, ty_offset)
end

function DungeonManager.populate_enemies(room, player, num_enemies, min_dist, types)
   if room.is_safe or room.cleared then return end

   -- Scale enemies by room area if not explicitly provided
   if not num_enemies then
      local area = room.tiles.w * room.tiles.h
      num_enemies = flr(area / 100) + 1
      num_enemies = mid(2, num_enemies, 4)
   end

   min_dist = min_dist or 96
   room.enemy_positions = {}

   local floor = room:get_inner_bounds()
   local attempts = 0
   while #room.enemy_positions < num_enemies and attempts < 200 do
      attempts = attempts + 1
      local tx = floor.x1 + flr(rnd(floor.x2 - floor.x1 + 1))
      local ty = floor.y1 + flr(rnd(floor.y2 - floor.y1 + 1))
      local rx = tx * GRID_SIZE
      local ry = ty * GRID_SIZE

      local dx = rx - player.x
      local dy = ry - player.y
      if dx * dx + dy * dy > min_dist * min_dist then
         if DungeonManager.is_free_space(room, rx, ry) then
            local etype = "Skulker"
            if rnd(1) < 0.4 then etype = "Shooter" end
            table.insert(room.enemy_positions, {x = rx, y = ry, type = etype})
         end
      end
   end

   if #room.enemy_positions > 0 then
      DungeonManager.lock_room(room)
   end
end

function DungeonManager.lock_room(room)
   room.is_locked = true
   if room.doors then
      for _, door in pairs(room.doors) do door.sprite = SPRITE_DOOR_BLOCKED end
      DungeonManager.apply_door_sprites(room)
   end
end

function DungeonManager.unlock_room(room)
   room.is_locked = false
   room.cleared = true
   if room.doors then
      for _, door in pairs(room.doors) do door.sprite = SPRITE_DOOR_OPEN end
      DungeonManager.apply_door_sprites(room)
   end
end

function DungeonManager.check_room_clear(room)
   if room.is_locked and #room.enemy_positions == 0 then
      DungeonManager.unlock_room(room)
   end
end

function DungeonManager.is_free_space(room, x, y)
   for _, pos in ipairs(room.enemy_positions) do
      local dx = x - pos.x
      local dy = y - pos.y
      if dx * dx + dy * dy < 16 * 16 then return false end
   end
   return true
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
   local dx, dy = 0, 0
   if direction == "east" then dx = 1 end
   if direction == "west" then dx = -1 end
   if direction == "north" then dy = -1 end
   if direction == "south" then dy = 1 end

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
   -- Create extended map userdata (80x48 tiles)
   DungeonManager.map_data = userdata("i16", EXT_MAP_W, EXT_MAP_H)

   -- Set as the current working map so mset/mget/map() work on it
   memmap(DungeonManager.map_data, 0x100000)

   Log.trace("Created extended map: "..EXT_MAP_W.."x"..EXT_MAP_H.." tiles")
   Log.trace("Base offset: ("..BASE_OFFSET_X..","..BASE_OFFSET_Y..") tiles")

   -- Generate dungeon
   DungeonManager.generate()
end

-- Get the base camera offset in pixels (for centering the view on the active area)
function DungeonManager.get_base_camera_offset()
   return {
      x = BASE_OFFSET_X * GRID_SIZE,
      y = BASE_OFFSET_Y * GRID_SIZE
   }
end

-- Peek at next room without committing transition (for RoomManager scroll animation)
function DungeonManager.peek_next_room(direction)
   local dx, dy = 0, 0
   if direction == "east" then dx = 1 end
   if direction == "west" then dx = -1 end
   if direction == "north" then dy = -1 end
   if direction == "south" then dy = 1 end

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
