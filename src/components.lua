return function(world)
   -- Identity/query tags (empty components for filtering)
   world:tag(
      "background", "chest", "controllable", "destructible", "enemy",
      "flying", "locked", "middleground", "minion", "obstacle",
      "pickup", "player", "projectile", "shop_item", "skull",
      "spotlight", "sprite", "static", "world_obj", "yolk_splat"
   )

   world:component("type", {value = "value"})
   world:component("position", {x = "f64", y = "f64", z = "f64"}) -- Added z support
   world:component("size", {width = "f64", height = "f64"})
   world:component("acceleration", {
      accel = "f64",
      friction = "f64",
      max_speed = "f64",
   })
   world:component("velocity", {
      vel_x = "f64",
      vel_y = "f64",
      sub_x = "f64",
      sub_y = "f64",
   })
   world:component("direction", {
      dir_x = "f64",
      dir_y = "f64",
      facing = "value", -- String: "up", "down", "left", "right"
   })
   world:component("collidable", {
      hitboxes = "value",       -- Table of per-direction hitboxes
      map_collidable = "value", -- Boolean flag
   })
   world:component("health", {
      hp = "u64",
      max_hp = "u64",
      overflow_hp = "u64",
      overflow_banking = "value", -- Boolean
   })
   world:component("health_regen", {
      regen_rate = "f64",
      regen_delay = "u64",
      regen_trigger_field = "value", -- String name of field
   })
   -- PRUNE: timers component - fields duplicated in shooter/invulnerability
   world:component("timers", {
      shoot_cooldown = "u64", -- PRUNE: duplicated in shooter.shoot_cooldown
      invuln_timer = "u64",   -- PRUNE: duplicated in invulnerability.invuln_timer
      hp_drain_timer = "u64", -- PRUNE: move to hp_drain component
   })
   world:component("shooter", {
      max_hp_to_shot_cost_ratio = "f64",
      max_hp_to_damage_ratio = "f64", -- PRUNE: overlaps with projectile_combat.damage
      shoot_cooldown = "u64",         -- PRUNE: duplicated in timers.shoot_cooldown
      shot_speed = "f64",
      time_since_shot = "u64",
      fire_rate = "f64",
      impact_damage = "f64", -- PRUNE: overlaps with projectile_combat.damage
      knockback = "f64",     -- PRUNE: overlaps with projectile_combat.knockback
      range = "f64",
      drain_damage = "f64",
      drain_heal = "f64",
      recovery_percent = "f64",
      hatch_time = "f64",
      health_as_ammo = "value",  -- Boolean
      projectile_type = "value", -- String
      projectile_origin_x = "f64",
      projectile_origin_y = "f64",
      projectile_origin_z = "f64",
      shoot_cooldown_duration = "u64",
   })
   world:component("melee", {
      melee_cooldown = "u64",
      melee_cost = "f64",
      melee_bonus_damage = "f64",
      vampiric_heal = "f64",
   })
   world:component("invulnerability", {
      invuln_timer = "u64", -- PRUNE: duplicated in timers.invuln_timer
      invulnerability_duration = "u64",
   })
   world:component("inventory", {
      coins = "u64",
      keys = "u64",
      bombs = "u64",
   })
   world:component("xp", {
      xp = "u64",
      level = "u64",
      xp_to_next_level = "u64",
   })
   world:component("shadow", {
      shadow_offset_x = "f64",
      shadow_offset_y = "f64",
      shadow_width = "f64",
      shadow_height = "f64",
      -- Config tables must be "value"
      shadow_offsets_x = "value",
      shadow_offsets_y = "value",
      shadow_widths = "value",
      shadow_heights = "value",
   })
   world:component("drawable", {
      outline_color = "value", -- Palette index
      sort_offset_y = "f64",
      sprite_index = "u64",
      flip_x = "value", -- Boolean
      flip_y = "value", -- Boolean
      -- Composite sprite support
      sprite_top = "u64",
      sprite_bottom = "u64",
      split_row = "f64",
   })
   world:component("animatable", {
      animations = "value",           -- Complex animation config table
      sprite_index_offsets = "value", -- PRUNE: could merge into animations
      anim_timer = "u64",             -- Animation frame timer
      anim_complete_state = "value",  -- Output: state that just finished
      anim_looping = "value",         -- Output: is current anim looping?
   })

   world:component("spotlight", {
      radius = "f64",
      color = "u64",
   })

   world:component("floating_text", {
      text = "value", -- String content
      color = "u64",
      outline_color = "u64",
      timer = "f64",
      rise_speed = "f64",
      fade_start = "f64",
      sprite_index = "u64", -- Optional icon
   })

   world:component("fsm", {
      value = "value", -- Generic FSM instance
   })

   ---------------------------------------------------------------------------
   -- Enemy components
   ---------------------------------------------------------------------------
   -- PRUNE: enemy_type - redundant with using `type` component
   world:component("enemy_type", {
      value = "value", -- String: "Skulker", "Shooter", "Dasher", "Skull"
   })
   world:component("enemy_ai", {
      fsm = "value",             -- lua-state-machine FSM instance
      vision_range = "f64",      -- PRUNE: overlaps with minion_ai fields
      wander_radius = "f64",     -- PRUNE: overlaps with minion_ai fields
      wander_speed_mult = "f64", -- PRUNE: overlaps with minion_ai fields
      wander_pause_min = "u64",  -- PRUNE: overlaps with minion_ai fields
      wander_pause_max = "u64",  -- PRUNE: overlaps with minion_ai fields
   })
   world:component("contact_damage", {
      damage = "f64",
   })
   -- PRUNE: enemy_shooter - overlaps with shooter component
   world:component("enemy_shooter", {
      shoot_delay = "u64",  -- PRUNE: use shooter.shoot_cooldown_duration
      is_shooter = "value", -- PRUNE: use shooter tag instead
   })
   world:component("dasher", {
      windup_duration = "u64",
      stun_duration = "u64",
      dash_speed_multiplier = "f64",
   })
   world:component("drop", {
      drop_chance = "f64",
      loot_rolls = "u64",
      use_diverse_loot = "value", -- Boolean
      xp_value = "u64",
   })

   world:component("flash", {
      flash_timer = "u64",
      flash_duration = "u64", -- Optional config
   })

   ---------------------------------------------------------------------------
   -- Projectile components
   ---------------------------------------------------------------------------
   -- PRUNE: projectile_type - redundant with using `type` component
   world:component("projectile_type", {
      value = "value", -- String: "Egg", "EnemyBullet"
   })
   -- REFACTOR: Migrate fields to core components and delete this component
   world:component("projectile_physics", {
      z = "f64",         -- REFACTOR: move to position.z
      vel_z = "f64",     -- REFACTOR: move to velocity.vel_z
      gravity_z = "f64", -- REFACTOR: move to acceleration.gravity_z
      age = "u64",       -- REFACTOR: move to new "lifetime" component
      max_age = "u64",   -- REFACTOR: move to new "lifetime" component
   })
   -- PRUNE: projectile_owner - could use tags "player_projectile" / "enemy_projectile"
   world:component("projectile_owner", {
      owner = "value", -- "player" or "enemy"
   })
   world:component("projectile_combat", {
      damage = "f64",    -- PRUNE: overlaps with shooter.impact_damage
      knockback = "f64", -- PRUNE: overlaps with shooter.knockback
   })

   ---------------------------------------------------------------------------
   -- Pickup components
   ---------------------------------------------------------------------------
   -- PRUNE: pickup_type - redundant with using `type` component
   world:component("pickup_type", {
      value = "value", -- String: "HealthPickup", "Coin", "Key", "Bomb", "DNAStrand" -- REVIEW: dynamic?
   })
   world:component("pickup_effect", {
      effect = "value",  -- String: "health", "coin", "key", "bomb", "xp"
      amount = "u64",    -- PRUNE: overlaps with recovery_amount/xp_amount
      recovery_amount = "u64",
      xp_amount = "u64", -- PRUNE: use amount instead
   })

   ---------------------------------------------------------------------------
   -- Minion components
   ---------------------------------------------------------------------------
   -- PRUNE: minion_type - redundant with using `type` component
   world:component("minion_type", {
      value = "value", -- String: "Chick", "YolkSplat", "Egg" -- REVIEW: dynamic?
   })
   -- PRUNE: minion_ai has overlapping fields with enemy_ai (fsm, vision, wander)
   -- Consider a shared "ai" component
   world:component("minion_ai", {
      fsm = "value", -- FSM instance
      food_seek_range = "f64",
      food_heal_amount = "u64",
      chase_speed_mult = "f64",
      attack_damage = "f64",
      attack_cooldown = "u64",
      attack_knockback = "f64",
      attack_range = "f64",
      follow_trigger_dist = "f64",
      follow_stop_dist = "f64",
      follow_speed_mult = "f64",
   })
   world:component("hp_drain", {
      hp_drain_rate = "u64", -- Frames between each 1 HP loss
      -- PRUNE: add hp_drain_timer here (from timers component)
   })

   ---------------------------------------------------------------------------
   -- Obstacle components
   ---------------------------------------------------------------------------
   -- PRUNE: obstacle_type - redundant with using `type` component
   world:component("obstacle_type", {
      value = "value",       -- String: "Rock", "Destructible", "Chest", etc.
   })
   world:component("loot", { -- REVIEW: dynamic?
      loot_min = "u64",
      loot_max = "u64",
      key_cost = "u64",
   })
   -- REVIEW: Used for room visibility filtering (obstacles only render in active room)
   -- Consider if this should be handled differently with picobloc queries
   world:component("room_key", {
      value = "value", -- String: "0,0", "1,0", etc.
   })
end
