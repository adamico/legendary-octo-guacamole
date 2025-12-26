-- World module aggregator
local Room = require("src/world/room")
local DungeonManager = require("src/world/dungeon_manager")
local RoomRenderer = require("src/world/room_renderer")
local CameraManager = require("src/world/camera_manager")

local World = {}

World.Room = Room
World.DungeonManager = DungeonManager
World.RoomRenderer = RoomRenderer
World.CameraManager = CameraManager

return World
