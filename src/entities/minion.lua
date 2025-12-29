-- Minion entity factory (for player-summoned entities)
-- Uses Type Object pattern like Enemy/Projectile factories
local GameConstants = require("src/game/game_config")
local EntityUtils = require("src/utils/entity_utils")

local Minion = {}

-- Spawn a minion at position
-- @param world - ECS world
-- @param x, y - spawn position
-- @param minion_type - type key in GameConstants.Minion (default: "Chick")
-- @param instance_data - optional table with instance-specific overrides
function Minion.spawn(world, x, y, minion_type, instance_data)
   minion_type = minion_type or "Chick"
   instance_data = instance_data or {}

   local config = GameConstants.Minion[minion_type]
   if not config then
      Log.error("Attempted to spawn unknown minion type: "..tostring(minion_type))
      return nil
   end

   -- 1. Base identity and physics state
   local minion = {
      type = config.entity_type or "Minion",
      minion_type = minion_type,
      tags = config.tags, -- Store tags for systems that check entity.tags
      x = x,
      y = y,
      vel_x = 0,
      vel_y = 0,
      sub_x = 0,
      sub_y = 0,
      dir_x = 1,
      dir_y = 0,
      hp = config.hp or 1,
      max_hp = config.hp or 1,
   }

   -- 2. Bulk copy all non-table values from config
   for k, v in pairs(config) do
      if type(v) ~= "table" then
         minion[k] = v
      end
   end

   -- 3. Static table references
   minion.sprite_index_offsets = config.sprite_index_offsets
   minion.shadow_offsets_y = config.shadow_offsets_y
   minion.shadow_offsets_x = config.shadow_offsets_x
   minion.shadow_widths = config.shadow_widths
   minion.shadow_heights = config.shadow_heights
   minion.animations = config.animations

   -- 4. Dynamic initialization
   minion.current_direction = "right" -- Default direction for animations
   minion.anim_state = "idle"         -- Default animation state
   if minion.sprite_index_offsets then
      minion.sprite_index = minion.sprite_index_offsets.right
   end

   -- 5. Apply instance overrides
   for k, v in pairs(instance_data) do
      minion[k] = v
   end

   -- 6. Create entity with tags from config
   return EntityUtils.spawn_entity(world, config.tags, minion)
end

return Minion
