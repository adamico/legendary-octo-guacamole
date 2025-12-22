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
local UI_SAFE_ZONE = 4 -- tiles on the left for UI
local MAP_W = 30       -- SCREEN_WIDTH / GRID_SIZE
local MAP_H = 17       -- SCREEN_HEIGHT / GRID_SIZE (effectively)

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

   -- 2. Create Adjacent Room at 1,0 (Enemy Room)
   local next_room_x = 1
   local next_room_y = 0
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

   -- Local position within the grid cell
   local area_w = MAP_W - UI_SAFE_ZONE
   local local_x = UI_SAFE_ZONE + flr((area_w - w) / 2)
   local local_y = flr((MAP_H - h) / 2)

   -- Global position (Grid Offset + Local) - REMOVED for Single Screen Mode
   local x = local_x
   local y = local_y

   local room = Room:new(x, y, w, h)

   -- Initialize spawner state
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

function DungeonManager.apply_door_sprites(room)
   if not room.doors then return end
   local cx, cy = room.tiles.x + flr(room.tiles.w / 2), room.tiles.y + flr(room.tiles.h / 2)

   if room.doors.north then mset(cx, room.tiles.y - 1, room.doors.north.sprite) end
   if room.doors.south then mset(cx, room.tiles.y + room.tiles.h, room.doors.south.sprite) end
   if room.doors.west then mset(room.tiles.x, cy, room.doors.west.sprite) end
   if room.doors.east then mset(room.tiles.x + room.tiles.w, cy, room.doors.east.sprite) end
end

function DungeonManager.carve_room(room, wall_options)
   wall_options = wall_options or {1, 2}
   local map_w = flr(SCREEN_WIDTH / GRID_SIZE)
   local map_h = flr(SCREEN_HEIGHT / GRID_SIZE)

   -- Fill room with walls
   for ty = room.tiles.y, room.tiles.y + room.tiles.h do
      for tx = room.tiles.x, room.tiles.x + room.tiles.w do
         local sprite = wall_options[1]
         if #wall_options > 1 and rnd() < 0.1 then
            sprite = wall_options[flr(rnd(#wall_options - 1)) + 2]
         end
         mset(tx, ty, sprite)
      end
   end

   -- Carve floor
   for ty = room.tiles.y + 1, room.tiles.y + room.tiles.h - 1 do
      for tx = room.tiles.x + 1, room.tiles.x + room.tiles.w - 1 do
         mset(tx, ty, 0)
      end
   end

   -- Place Doors
   DungeonManager.apply_door_sprites(room)
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

   local attempts = 0
   while #room.enemy_positions < num_enemies and attempts < 200 do
      attempts = attempts + 1
      local rx = (room.tiles.x + 1 + rnd(room.tiles.w - 2)) * GRID_SIZE
      local ry = (room.tiles.y + 1 + rnd(room.tiles.h - 2)) * GRID_SIZE

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
   local map_w = flr(SCREEN_WIDTH / GRID_SIZE)
   local map_h = flr(SCREEN_HEIGHT / GRID_SIZE)
   for ty = 0, map_h - 1 do
      for tx = 0, map_w - 1 do
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
   DungeonManager.generate()
end

function DungeonManager.draw()
   if DungeonManager.current_room then
      DungeonManager.current_room:draw()
   end
end

return DungeonManager
