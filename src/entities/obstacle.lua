local GameConstants = require("src/game/game_config")
local Utils = require("src/utils/entity_utils")

local Obstacle = {}

-- Spawn generic obstacle (Rock, Destructible)
function Obstacle.spawn(world, x, y, obstacle_type, sprite_override)
   local config = GameConstants.Obstacle[obstacle_type]
   if not config then
      Log.error("Unknown obstacle type: "..tostring(obstacle_type))
      return nil
   end

   -- Create entity data by merging config + instance data
   local entity_data = {}
   -- Copy config first
   for k, v in pairs(config) do entity_data[k] = v end
   -- Apply overrides
   if sprite_override then
      entity_data.sprite_index = sprite_override
   end

   -- Use standard spawn_entity utility to handle tagging and shadows
   local entity = Utils.spawn_entity(world, config.tags, entity_data)

   entity.type = config.entity_type

   -- Set position directly
   entity.x = x
   entity.y = y

   return entity
end

return Obstacle
