-- Obstacle entity factory (picobloc version)
-- Obstacles: Rock, Destructible, Chest, LockedChest, ShopItem
local GameConstants = require("src/game/game_config")

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

   -- Parse tags from comma-separated config string
   local tag_set = {}
   for tag in all(split(config.tags or "", ",")) do
      tag_set[tag] = true
   end

   -- Build entity with components
   local entity = {
      -- Type identifier
      type = {value = config.entity_type or obstacle_type},
      obstacle_type = {value = obstacle_type},

      -- Transform
      position = {x = x, y = y},
      size = {width = config.width or 16, height = config.height or 16},

      -- Collision
      collidable = {
         hitboxes = {
            w = config.hitbox_width or 16,
            h = config.hitbox_height or 16,
            ox = config.hitbox_offset_x or 0,
            oy = config.hitbox_offset_y or 0,
         },
         map_collidable = false,
      },

      -- Visuals: Drawable
      drawable = {
         outline_color = config.outline_color,
         sort_offset_y = 0,
         sprite_index = sprite_override or config.sprite_index or 0,
         flip_x = false,
         flip_y = false,
      },
   }

   -- Copy all parsed tags into entity
   for tag, _ in pairs(tag_set) do
      entity[tag] = true
   end

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
