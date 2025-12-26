-- World module aggregator
local Room = require("world/room")
local DungeonManager = require("world/dungeon_manager")
local RoomRenderer = require("world/room_renderer")
local CameraManager = require("world/camera_manager")

local World = {}

World.Room = Room
World.DungeonManager = DungeonManager
World.RoomRenderer = RoomRenderer
World.CameraManager = CameraManager

return World
