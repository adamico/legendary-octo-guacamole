-- Scenes module aggregator
local Play = require("scenes/play")
local Title = require("scenes/title")
local GameOver = require("scenes/game_over")

local Scenes = {}
Scenes.Play = Play
Scenes.Title = Title
Scenes.GameOver = GameOver

return Scenes
