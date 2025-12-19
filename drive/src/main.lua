include("lib/require.lua")
include("lib/debugui.lua")
include("lib/eggs.p8/eggs.lua")

add_module_path("lib/")
add_module_path("src/")
add_module_path("src/scenes/")

Class = require("middleclass")
Stateful = require("stateful")
GameConstants = require("constants")

Log = require("log")
Log.init("trace")
Log.trace("Log.init: current_level = "..Log.current_level)

local Sound
-- local SoundManager = require("sound_manager")
local sound_enabled = false

local SceneManager = require("scene_manager")
local Title = require("title")
local Play = require("play")
local GameOver = require("game_over")

local starting_scene = "Play"
local Scene = SceneManager:new()

function _init()
   -- Sound = SoundManager:new(sound_enabled)
   Scene:gotoState(starting_scene)
end

function _update()
   Scene:update()
end

function _draw()
   Scene:draw()
   debugui.run()
end

include("lib/error_explorer.lua")
