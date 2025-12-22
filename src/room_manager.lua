local Room = require("room")

local RoomManager = {}

RoomManager.current_room = nil

-- Constants for procedural generation
local MIN_ROOM_W = 10
local MAX_ROOM_W = 22
local MIN_ROOM_H = 8
local MAX_ROOM_H = 14
local UI_SAFE_ZONE = 4 -- tiles on the left for UI
local MAP_W = 30       -- SCREEN_WIDTH / GRID_SIZE
local MAP_H = 17       -- SCREEN_HEIGHT / GRID_SIZE (effectively)

function RoomManager.create_room(x, y, w, h, wall_options)
   local room = Room:new(x, y, w, h)

   -- Initialize spawner state on the room instance
   room.enemy_positions = {}
   room.spawn_timer = 60
   room.spawned = false

   -- Perform carving
   RoomManager.carve(room, wall_options)

   return room
end

function RoomManager.carve(room, wall_options)
   wall_options = wall_options or {1, 2}
   local map_w = flr(SCREEN_WIDTH / GRID_SIZE)
   local map_h = flr(SCREEN_HEIGHT / GRID_SIZE)

   -- Fill screen with walls
   for ty = 0, map_h - 1 do
      for tx = 0, map_w - 1 do
         local sprite = wall_options[1]
         if #wall_options > 1 and rnd() < 0.1 then
            sprite = wall_options[flr(rnd(#wall_options - 1)) + 2]
         end
         mset(tx, ty, sprite)
      end
   end

   -- Carve floor
   for ty = room.tiles.y, room.tiles.y + room.tiles.h - 1 do
      for tx = room.tiles.x, room.tiles.x + room.tiles.w - 1 do
         mset(tx, ty, 0)
      end
   end
end

function RoomManager.populate_enemies(room, player, num_enemies, min_dist, types)
   -- Scale enemies by room area if not explicitly provided
   -- Drastically reduced density for the first monster room based on research/balancing
   if not num_enemies then
      local area = room.tiles.w * room.tiles.h
      -- area ranges from ~80 to ~300.
      -- flr(area / 100) + 2 results in 2-5 enemies.
      num_enemies = flr(area / 100) + 1
      num_enemies = mid(3, num_enemies, 5) -- Hard limit for the first room: 3-5 enemies
   end

   min_dist = min_dist or 96 -- Slightly increased from 80 for better breathing room
   room.enemy_positions = {}

   local attempts = 0
   while #room.enemy_positions < num_enemies and attempts < 200 do
      attempts = attempts + 1
      -- Calculate random position within floor area (inset by 1 tile to avoid spawning touching walls)
      local rx = (room.tiles.x + 1 + rnd(room.tiles.w - 2)) * GRID_SIZE
      local ry = (room.tiles.y + 1 + rnd(room.tiles.h - 2)) * GRID_SIZE

      -- Ensure distance from player
      local dx = rx - player.x
      local dy = ry - player.y
      if dx * dx + dy * dy > min_dist * min_dist then
         -- Ensure far from other enemies
         if RoomManager.is_free_space(room, rx, ry) then
            -- Weighted enemy selection (60% Skulker, 40% Shooter)
            local etype = "Skulker"
            if rnd(1) < 0.4 then
               etype = "Shooter"
            end
            table.insert(room.enemy_positions, {x = rx, y = ry, type = etype})
         end
      end
   end
end

function RoomManager.is_free_space(room, x, y)
   -- Check against other enemy positions to prevent stacking
   for _, pos in ipairs(room.enemy_positions) do
      local dx = x - pos.x
      local dy = y - pos.y
      if dx * dx + dy * dy < 16 * 16 then
         return false
      end
   end
   return true
end

function RoomManager.init()
   -- Random dimensions
   local w = flr(rnd(MAX_ROOM_W - MIN_ROOM_W + 1)) + MIN_ROOM_W
   local h = flr(rnd(MAX_ROOM_H - MIN_ROOM_H + 1)) + MIN_ROOM_H

   -- Centering within available space (excluding UI safe zone)
   local area_w = MAP_W - UI_SAFE_ZONE
   local x = UI_SAFE_ZONE + flr((area_w - w) / 2)
   local y = flr((MAP_H - h) / 2)

   RoomManager.current_room = RoomManager.create_room(x, y, w, h, {1, 2})
end

function RoomManager.draw()
   RoomManager.current_room:draw()
end

return RoomManager
