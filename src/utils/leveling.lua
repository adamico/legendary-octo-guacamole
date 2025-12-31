-- Leveling utility module
-- Handles XP accumulation and level progression (player-specific, not ECS system)
local GameConstants = require("src/game/game_config")
local Events = require("src/game/events")

local Leveling = {}

-- Calculate XP needed for a given level (linear for levels 1-10)
function Leveling.xp_for_level(level)
   local base = GameConstants.Player.base_xp_to_level
   local linear = GameConstants.Player.xp_per_level_linear
   return base + (level - 1) * linear
end

-- Check and process level ups (called from play.lua with player entity)
function Leveling.check_level_up(player)
   if not player then return end

   local required = player.xp_to_next_level or Leveling.xp_for_level(player.level or 1)

   while player.xp >= required do
      player.xp = player.xp - required
      player.level = player.level + 1
      player.xp_to_next_level = Leveling.xp_for_level(player.level)
      required = player.xp_to_next_level

      -- Emit level up event for UI/effects
      Events.emit(Events.LEVEL_UP, player, player.level)
   end
end

return Leveling
