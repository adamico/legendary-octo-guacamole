-- Game module aggregator
-- Provides Config (immutable) and State (mutable runtime values)

local Game = {
   Config = require("src/game/game_config"),
   State = require("src/game/game_state"),
}

return Game
