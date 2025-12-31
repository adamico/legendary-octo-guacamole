-- Game State: Mutable runtime values (cheats, debug flags)
-- These values change during gameplay and should not be in config

local GameState = {
   debug = {
      show_hitboxes = false,
      show_grid = false,         -- Debug: show tile grid overlay
      show_pathfinding = false,  -- Debug: show chick AI paths and targets
      show_combat_timer = false, -- Debug: show time since combat started
   },
   cheats = {
      noclip = false,
      godmode = false,
      free_attacks = false, -- Removes shot/melee costs and activation conditions
      infinite_inventory = false,
   },
   -- Level seed for reproducible dungeon generation (nil = random)
   level_seed = nil,
   -- The actual seed used for the current level (set at generation time)
   current_seed = nil,
}

return GameState
