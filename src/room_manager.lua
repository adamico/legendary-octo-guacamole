local Room = require("room")

local RoomManager = {}

-- RoomManager State
RoomManager.current_room = nil

function RoomManager.create_room(x, y, w, h)
   return Room:new(x, y, w, h)
end

function RoomManager.init()
   RoomManager.current_room = RoomManager.create_room(7, 3, 12, 11)
end

function RoomManager.draw()
   RoomManager.current_room:draw()
end

return RoomManager
