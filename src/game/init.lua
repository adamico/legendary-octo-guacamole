-- Game module aggregator
-- Provides Config (immutable), State (mutable runtime values), and Events

local Game = {
   Config = require("src/game/game_config"),
   State = require("src/game/game_state"),
   Events = require("src/game/events"),
}

return Game
