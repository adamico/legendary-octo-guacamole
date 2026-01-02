local GameConstants = require("src/game/game_config")
local EntityUtils = require("src/utils/entity_utils")

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
      size = EntityUtils.build_size(cfg),

      -- Movement
      acceleration = EntityUtils.build_acceleration(cfg, {accel = 1.2}),
      velocity = EntityUtils.build_velocity(),
      direction = EntityUtils.build_direction(0, 1), -- Default facing down

      -- Collision
      collidable = EntityUtils.build_collidable(cfg, {map_collidable = true}),

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

      -- Timers
      timers = EntityUtils.build_timers(),

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

      -- Visuals
      shadow = EntityUtils.build_shadow(cfg),
      drawable = EntityUtils.build_drawable(cfg, "down"),
      animatable = EntityUtils.build_animatable(cfg),

      -- FSM (required for Lifecycle system to manage idle/walking/etc states)
      fsm = {value = nil}, -- Initialized by Lifecycle.init_fsm
   })

   return id
end

return Player
