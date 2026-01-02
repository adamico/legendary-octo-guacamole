-- Player entity factory (picobloc version)
local GameConstants = require("src/game/game_config")

local Player = {}

function Player.spawn(world, x, y)
   local cfg = GameConstants.Player

   local id = world:add_entity({
      -- Identity tags (use `true` shorthand)
      player = true,
      controllable = true,
      sprite = true,
      middleground = true,
      spotlight = true,

      -- Type identifier
      type = {value = "Player"},

      -- Transform
      position = {x = x, y = y},
      size = {width = cfg.width, height = cfg.height},

      -- Movement
      acceleration = {
         accel = 1.2,
         friction = 0.5,
         max_speed = cfg.max_speed,
      },
      velocity = {
         vel_x = 0,
         vel_y = 0,
         sub_x = 0,
         sub_y = 0,
      },
      direction = {
         dir_x = 0,
         dir_y = 1,       -- Default facing down
         facing = "down", -- Must be set explicitly (0 would break animation lookup)
      },

      -- Collision (supports both 'hitbox' for single and 'hitboxes' for per-direction)
      collidable = {
         hitboxes = cfg.hitboxes or cfg.hitbox,
         map_collidable = true,
      },

      -- Health
      health = {
         hp = cfg.max_health,
         max_hp = cfg.max_health,
         overflow_hp = 0,
         overflow_banking = true,
      },
      health_regen = {
         regen_rate = cfg.regen_rate,
         regen_delay = cfg.regen_delay,
         regen_trigger_field = "time_since_shot",
      },

      -- Timers (REFACTOR: duplicates some fields)
      timers = {
         shoot_cooldown = 0,
         invuln_timer = 0,
         hp_drain_timer = 0,
      },

      -- Combat: Shooter
      shooter = {
         max_hp_to_shot_cost_ratio = cfg.max_hp_to_shot_cost_ratio,
         max_hp_to_damage_ratio = cfg.max_hp_to_damage_ratio,
         shoot_cooldown = 0,
         shot_speed = cfg.shot_speed,
         time_since_shot = 0,
         fire_rate = cfg.fire_rate,
         impact_damage = cfg.dud_damage or 3,
         knockback = cfg.base_knockback,
         range = cfg.range,
         drain_damage = cfg.leech_damage or 5,
         drain_heal = cfg.leech_heal or 5,
         recovery_percent = cfg.recovery_percent,
         hatch_time = cfg.hatch_time,
         health_as_ammo = true,
         projectile_type = "Egg",
         projectile_origin_x = cfg.projectile_origin_x or 0,
         projectile_origin_y = cfg.projectile_origin_y or 0,
         projectile_origin_z = cfg.projectile_origin_z or 0,
         shoot_cooldown_duration = cfg.fire_rate,
      },

      -- Combat: Melee
      melee = {
         melee_cooldown = 0,
         melee_cost = cfg.melee_cost,
         melee_bonus_damage = 0,
         vampiric_heal = cfg.vampiric_heal or 0.3,
      },

      -- Combat: Invulnerability
      invulnerability = {
         invuln_timer = 0,
         invulnerability_duration = cfg.invulnerable_time or 120,
      },

      -- Inventory
      inventory = {
         coins = cfg.coins,
         keys = cfg.keys,
         bombs = cfg.bombs,
      },

      -- XP/Leveling
      xp = {
         xp = cfg.starting_xp,
         level = cfg.starting_level,
         xp_to_next_level = cfg.base_xp_to_level,
      },

      -- Visuals: Shadow
      shadow = {
         shadow_offset_x = cfg.shadow_offset_x or 0,
         shadow_offset_y = cfg.shadow_offset_y or 0,
         shadow_width = cfg.shadow_width,
         shadow_height = cfg.shadow_height,
         shadow_offsets_x = cfg.shadow_offsets_x,
         shadow_offsets_y = cfg.shadow_offsets_y,
         shadow_widths = cfg.shadow_widths,
         shadow_heights = cfg.shadow_heights,
      },

      -- Visuals: Drawable
      drawable = {
         outline_color = cfg.outline_color,
         sort_offset_y = cfg.sort_offset_y,
         sprite_index = cfg.sprite_index_offsets.down,
         flip_x = false,
         flip_y = false,
      },

      -- Visuals: Animation
      animatable = {
         animations = cfg.animations,
         sprite_index_offsets = cfg.sprite_index_offsets,
      },
   })

   return id
end

return Player
