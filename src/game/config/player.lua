-- Player configuration
return {
   invulnerable_time = 120, -- frames
   width = 24,
   height = 32,
   max_health = 100,
   max_hp_to_shot_cost_ratio = 0.05, -- 5 hp per shot
   recovery_percent = 0.8,           -- I don't think we need this anymore
   regen_rate = 0,
   regen_delay = 1.5,
   -- XP System
   starting_level = 1,
   starting_xp = 0,
   base_xp_to_level = 50,         -- XP to reach level 2
   xp_per_level_linear = 25,      -- Linear growth for levels 1-10
   -- Stats
   max_speed = 2,                 -- Movement speed
   shot_speed = 4,
   max_hp_to_damage_ratio = 0.05, -- Damage = max_hp * ratio
   range = 100,                   -- Max distance in pixels
   fire_rate = 15,                -- Frames between shots
   base_knockback = 4,            -- Base knockback applied to all player attacks
   vampiric_heal = 0.3,           -- Heal player for 30% of damage dealt, is this used?
   -- Egg outcome probabilities (single roll, 3 outcomes)
   -- 50% The Dud: 3 Dmg, splats harmlessly
   -- 35% The Hatching: 0 Dmg, spawns Chick
   -- 15% The Leech: 5 Dmg, drops 5 HP glob
   roll_dud_chance = 0.50,
   roll_hatch_chance = 0.35,
   roll_leech_chance = 0.15,

   dud_damage = 3,   -- Damage dealt by "The Dud" (and splat visual)
   leech_damage = 5, -- Damage dealt by "The Leech"
   leech_heal = 5,   -- HP pickup dropped by "The Leech"
   hatch_time = 120, -- Frames for egg to hatch into chick

   -- Sticky Yolk Effect (applied on egg impacts with enemies)
   egg_stun_duration = 12, -- Frames of micro-stun (~0.2s)
   egg_slow_duration = 60, -- Frames of 50% slow (~1s)
   egg_slow_factor = 0.5,  -- Speed multiplier during slow

   -- Face-Hugger (chick attachment on direct hit)
   chick_attach_duration = 60, -- Frames chick stays attached (~1s)

   -- Yolk Splat Settings (Wall/Rock impacts)
   yolk_splat_duration = 300, -- 5 seconds
   yolk_slow_factor = 0.7,    -- Enemies move at 70% speed
   projectile_origin_x = 12,  -- X offset from sprite left edge
   projectile_origin_y = 24,  -- Y offset from sprite top edge
   projectile_origin_z = 16,  -- Z elevation for horizontal shots
   -- Muzzle flash offsets per direction (from sprite top-left)
   muzzle_flash_offsets = {
      down  = {x = 12, y = 30},
      up    = {x = 12, y = 18},
      right = {x = 24, y = 24},
      left  = {x = 4, y = 24},
   },
   muzzle_flash_colors = {7, 6, 12}, -- white, light gray, light blue
   -- Inventory
   coins = 0,
   keys = 1,
   bombs = 2,
   animations = {
      down = {
         idle      = {indices = {1, 10, 1, 2}, durations = {20, 20, 20, 20}},
         walking   = {indices = {3, 4}, durations = {15, 15}},
         attacking = {indices = {1, 5}, durations = {4, 15}},
         hurt      = {indices = {8}, durations = {30}},
         death     = {indices = {9}, durations = {8}}
      },
      right = {
         idle      = {indices = {13, 11, 12, 11}, durations = {20, 20, 20, 20}},
         walking   = {indices = {14, 15}, durations = {8, 8}},
         attacking = {indices = {11, 16}, durations = {4, 15}},
         hurt      = {indices = {19}, durations = {30}},
         death     = {indices = {9}, durations = {8}}
      },
      up = {
         idle      = {indices = {20, 20, 21, 20}, durations = {20, 20, 20, 20}},
         walking   = {indices = {22, 23}, durations = {8, 8}},
         attacking = {indices = {20, 24}, durations = {8, 15}},
         hurt      = {indices = {8}, durations = {30}},
         death     = {indices = {9}, durations = {8}}
      },
      left = {
         idle      = {indices = {13, 11, 12, 11}, durations = {20, 20, 20, 20}, flip = true},
         walking   = {indices = {14, 15}, durations = {8, 8}, flip = true},
         attacking = {indices = {11, 16}, durations = {4, 15}, flip = true},
         hurt      = {indices = {19}, durations = {30}, flip = true},
         death     = {indices = {9}, durations = {8}, flip = true}
      }
   },
   sprite_index_offsets = {
      down = 1,
      right = 10,
      left = 10,
      up = 18,
   },
   shadow_offset_x = 0,
   shadow_offset_y = 3,
   shadow_width = 15,
   shadow_height = 6,
   outline_color = 1,
   sort_offset_y = 38,
   height_z = 25, -- Vertical collision height (human body, projectiles above this miss)
   -- Per-direction hitboxes (use 'hitbox = {w, h, ox, oy}' for same hitbox all directions)
   hitboxes = {
      down  = {w = 10, h = 12, ox = 7, oy = 18},
      up    = {w = 10, h = 12, ox = 7, oy = 18},
      right = {w = 10, h = 12, ox = 7, oy = 18},
      left  = {w = 10, h = 12, ox = 7, oy = 18},
   },
   melee_cost = 2,
   melee_cooldown = 60,
   melee_sprite = 57,
   melee_range = 14,
   melee_hitboxes = {
      down  = {w = 14, h = 16, ox = 3, oy = 16},
      up    = {w = 12, h = 12, ox = 4, oy = 10},
      right = {w = 16, h = 12, ox = 5, oy = 20},
      left  = {w = 16, h = 12, ox = 4, oy = 18},
   },
   melee_width = 9,
   melee_height = 16,
   melee_duration = 15,
   melee_knockback = 6,
   mutations = {
      Eggsaggerated = 0,
      Broodmother = 0,
      Pureblood = 0,
   },
}
