return function(world)
   -- Identity/query tags (empty components for filtering)
   world:component("player", {})
   world:component("controllable", {})
   world:component("sprite", {})

   world:component("type", {type = "value"})
   world:component("position", {x = "f64", y = "f64"})
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
   -- REFACTOR: timers duplicates fields from shooter and invulnerability.
   -- Consider removing this component and querying those directly.
   world:component("timers", {
      shoot_cooldown = "u64", -- DUPLICATE: also in shooter
      invuln_timer = "u64",   -- DUPLICATE: also in invulnerability
      hp_drain_timer = "u64",
   })
   world:component("shooter", {
      max_hp_to_shot_cost_ratio = "f64",
      max_hp_to_damage_ratio = "f64",
      shoot_cooldown = "u64", -- DUPLICATE: also in timers
      shot_speed = "f64",
      time_since_shot = "u64",
      fire_rate = "f64",
      impact_damage = "f64",
      knockback = "f64",
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
      invuln_timer = "u64", -- DUPLICATE: also in timers
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
   world:component("spotlight", {
      spotlight = "value", -- Boolean or config
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
   world:component("middleground", {
      middleground = "value", -- Boolean
   })
   world:component("drawable", {
      drawable = "value",      -- Boolean
      outline_color = "value", -- Palette index
      sort_offset_y = "f64",
      sprite_index = "u64",
      flip_x = "value", -- Boolean
      flip_y = "value", -- Boolean
   })
   world:component("animatable", {
      animatable = "value",           -- Boolean
      animations = "value",           -- Complex animation config table
      sprite_index_offsets = "value", -- Offset table
   })
end
