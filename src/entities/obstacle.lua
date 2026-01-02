-- Obstacle entity factory
-- Obstacles: Rock, Destructible, Chest, LockedChest, ShopItem
local GameConstants = require("src/game/game_config")
local EntityUtils = require("src/utils/entity_utils")

local Obstacle = {}

--- Spawn generic obstacle
--- @param world ECSWorld - picobloc World
--- @param x number - spawn x position
--- @param y number - spawn y position
--- @param obstacle_type string - type key in GameConstants.Obstacle
--- @param sprite_override number|nil - optional sprite index override
function Obstacle.spawn(world, x, y, obstacle_type, sprite_override)
   local config = GameConstants.Obstacle[obstacle_type]
   if not config then
      Log.error("Unknown obstacle type: "..tostring(obstacle_type))
      return nil
   end

   -- Parse tags from config
   local tag_set = EntityUtils.parse_tags(config.tags)

   -- Build entity with centralized component builders
   local entity = {
      -- Type identifier
      type = {value = config.entity_type or obstacle_type},
      obstacle_type = {value = obstacle_type},

      -- Transform
      position = {x = x, y = y},
      size = EntityUtils.build_size(config),

      -- Collision
      collidable = EntityUtils.build_collidable(config, {map_collidable = false}),

      -- Visuals
      drawable = EntityUtils.build_drawable(config),
   }

   -- Apply sprite override if provided
   if sprite_override then
      entity.drawable.sprite_index = sprite_override
   end

   -- Apply parsed tags
   EntityUtils.apply_tags(entity, tag_set)

   -- Add chest-specific components
   if config.is_chest then
      entity.loot = {
         loot_min = config.loot_min or 1,
         loot_max = config.loot_max or 3,
         key_cost = config.key_cost or 0,
      }
   end

   -- Add health component for chests and destructibles
   if config.is_chest or config.destructible then
      entity.health = {
         hp = config.hp or 1,
         max_hp = config.hp or 1,
         overflow_hp = 0,
         overflow_banking = false,
      }
   end

   local id = world:add_entity(entity)
   return id
end

return Obstacle
