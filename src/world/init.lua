-- World module aggregator
local Room = require("src/world/room")
local DungeonManager = require("src/world/dungeon_manager")
local RoomRenderer = require("src/world/room_renderer")
local CameraManager = require("src/world/camera_manager")
local WavePatterns = require("src/world/wave_patterns")
local RoomLayouts = require("src/world/room_layouts")
local FloorPatterns = require("src/world/floor_patterns")

local World = {}

World.Room = Room
World.DungeonManager = DungeonManager
World.RoomRenderer = RoomRenderer
World.CameraManager = CameraManager
World.WavePatterns = WavePatterns
World.RoomLayouts = RoomLayouts
World.FloorPatterns = FloorPatterns

return World
