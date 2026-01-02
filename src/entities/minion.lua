-- Minion entity factory (picobloc version)
-- Uses Type Object pattern for player-summoned entities
local GameConstants = require("src/game/game_config")
local EntityUtils = require("src/utils/entity_utils")

local Minion = {}

-- Spawn a minion at position
--- @param world ECSWorld - picobloc World
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

   -- Parse tags from config
   local tag_set = EntityUtils.parse_tags(config.tags)

   -- Build entity with centralized component builders
   local entity = {
      -- Type identifier
      type = {value = config.entity_type or "Minion"},
      minion_type = {value = minion_type},

      -- Transform
      position = {x = x, y = y},
      size = EntityUtils.build_size(config),

      -- Movement
      acceleration = EntityUtils.build_acceleration(config, {max_speed = 1}),
      velocity = EntityUtils.build_velocity(),
      direction = EntityUtils.build_direction(1, 0), -- Default facing right

      -- Collision
      collidable = EntityUtils.build_collidable(config, {
         map_collidable = true,
         w = 10,
         h = 10,
         ox = 3,
         oy = 3
      }),

      -- Health
      health = EntityUtils.build_health(config),

      -- Timers
      timers = EntityUtils.build_timers(),

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

      -- Visuals
      shadow = EntityUtils.build_shadow(config),
      drawable = EntityUtils.build_drawable(config, "right"),
      animatable = EntityUtils.build_animatable(config),
   }

   -- Apply parsed tags
   EntityUtils.apply_tags(entity, tag_set)

   -- Chicks can display emotions (not YolkSplat or Egg)
   if minion_type == "Chick" then
      entity.emotional = true
   end

   local id = world:add_entity(entity)
   return id
end

return Minion
