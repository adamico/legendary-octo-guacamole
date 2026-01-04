include("lib/require.lua")
include("lib/debugui.lua")
include("lib/eggs.p8/eggs.lua")

Class = require("lib/middleclass")
Stateful = require("lib/stateful")

Log = require("lib/log")
Log.init("trace")
Log.trace("Log.init: current_level = "..Log.current_level)

local Scenes = require("src/scenes")

local starting_scene = "Title"
local scene_manager = Scenes.Manager:new()

function _init()
   scene_manager:gotoState(starting_scene)
end

function _update()
   scene_manager:update()
end

function _draw()
   scene_manager:draw()
   debugui.run()
end

include("lib/error_explorer.lua")
