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
   return Room:new(x, y, w, h, wall_options)
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
