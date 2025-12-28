-- Game State: Mutable runtime values (cheats, debug flags)
-- These values change during gameplay and should not be in config

local GameState = {
   debug = {
      show_hitboxes = false,
      show_grid = false, -- Debug: show tile grid overlay
   },
   cheats = {
      noclip = false,
      godmode = false,
      free_attacks = false, -- Removes shot/melee costs and activation conditions
   },
}

return GameState
