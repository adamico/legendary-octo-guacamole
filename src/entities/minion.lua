-- Minion entity factory (picobloc version)
-- Uses Type Object pattern for player-summoned entities
local GameConstants = require("src/game/game_config")
local EntityUtils = require("src/utils/entity_utils")

local Minion = {}

-- Spawn a minion at position
--- @param world World - picobloc World
--- @param x number - spawn x position
--- @param y number - spawn y position
--- @param minion_type string - type key in GameConstants.Minion (default: "Chick")
--- @param instance_data table - optional table with instance-specific overrides
function Minion.spawn(world, x, y, minion_type, instance_data)
   minion_type = minion_type or "Chick"
   instance_data = instance_data or {}

   local config = GameConstants.Minion[minion_type]
   if not config then
      Log.error("Attempted to spawn unknown minion type: "..tostring(minion_type))
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
      type = {value = config.entity_type or "Minion"},
      minion_type = {value = minion_type},

      -- Transform
      position = {x = x, y = y},
      size = {width = config.width or 16, height = config.height or 16},

      -- Movement
      acceleration = {
         accel = 0,
         friction = 0.5,
         max_speed = config.max_speed or 1,
      },
      velocity = {
         vel_x = 0,
         vel_y = 0,
         sub_x = 0,
         sub_y = 0,
      },
      direction = {
         dir_x = 1,
         dir_y = 0, -- Default facing right
      },

      -- Collision
      collidable = {
         hitboxes = {
            w = config.hitbox_width or 10,
            h = config.hitbox_height or 10,
            ox = config.hitbox_offset_x or 3,
            oy = config.hitbox_offset_y or 3,
         },
         map_collidable = tag_set.map_collidable or false,
      },

      -- Health
      health = {
         hp = config.hp or 20,
         max_hp = config.hp or 20,
         overflow_hp = 0,
         overflow_banking = false,
      },

      -- Timers
      timers = {
         shoot_cooldown = 0,
         invuln_timer = 0,
         hp_drain_timer = 0,
      },

      -- HP Drain
      hp_drain = {
         hp_drain_rate = config.hp_drain_rate or 60,
      },

      -- AI
      minion_ai = {
         fsm = nil,
         food_seek_range = config.food_seek_range or 120,
         food_heal_amount = config.food_heal_amount or 5,
         chase_speed_mult = config.chase_speed_mult or 2,
         attack_damage = config.attack_damage or 3,
         attack_cooldown = config.attack_cooldown or 30,
         attack_knockback = config.attack_knockback or 3,
         attack_range = config.attack_range or 16,
         follow_trigger_dist = config.follow_trigger_dist or 100,
         follow_stop_dist = config.follow_stop_dist or 50,
         follow_speed_mult = config.follow_speed_mult or 3,
      },

      -- Visuals: Shadow
      shadow = {
         shadow_offset_x = config.shadow_offset_x or 0,
         shadow_offset_y = config.shadow_offset_y or 0,
         shadow_width = config.shadow_width or 8,
         shadow_height = config.shadow_height or 3,
         shadow_offsets_x = config.shadow_offsets_x,
         shadow_offsets_y = config.shadow_offsets_y,
         shadow_widths = config.shadow_widths,
         shadow_heights = config.shadow_heights,
      },

      -- Visuals: Drawable
      drawable = {
         outline_color = nil,
         sort_offset_y = 0,
         sprite_index = EntityUtils.get_sprite_index(config, "right"),
         flip_x = false,
         flip_y = false,
      },

      -- Visuals: Animation
      animatable = {
         animations = config.animations,
         sprite_index_offsets = config.sprite_index_offsets,
      },
   }

   -- Copy all parsed tags into entity
   for tag, _ in pairs(tag_set) do
      entity[tag] = true
   end

   local id = world:add_entity(entity)
   return id
end

return Minion
