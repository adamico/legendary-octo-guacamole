-- Scenes module aggregator
-- Manager must be required first (scenes depend on it for addState)
local Manager = require("src/scenes/manager")
local Play = require("src/scenes/play")
local Title = require("src/scenes/title")
local GameOver = require("src/scenes/game_over")

local Scenes = {}
Scenes.Manager = Manager
Scenes.Play = Play
Scenes.Title = Title
Scenes.GameOver = GameOver

return Scenes
