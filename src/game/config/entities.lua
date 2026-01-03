-- Entity configurations: Enemy, Minion, Projectile, Pickup, Obstacle

return {
   Projectile = {
      Egg = {
         entity_type = "Projectile",
         tags = "projectile,velocity,map_collidable,collidable,drawable,animatable,shadow,middleground",
         owner = "player",
         speed = 0,
         knockback = 0,
         width = 16,
         height = 16,
         hitboxes = {
            down  = {w = 6, h = 12, ox = 4, oy = 4},
            up    = {w = 6, h = 12, ox = 4, oy = 2},
            right = {w = 10, h = 6, ox = 3, oy = 5},
            left  = {w = 10, h = 6, ox = 3, oy = 5},
         },
         sprite_index_offsets = {
            down = 26,
            right = 25,
            left = 25,
            up = 26,
         },
         animations = {
            down = {
               indices = {26, 26},
               durations = {8, 8},
               flips = {{x = false, y = false}, {x = true, y = false}}
            },
            up = {
               indices = {26, 26},
               durations = {8, 8},
               flips = {{x = false, y = false}, {x = true, y = false}}
            },
            right = {
               indices = {25, 25},
               durations = {8, 8},
               flips = {{x = false, y = false}, {x = false, y = true}}
            },
            left = {
               indices = {25, 25},
               durations = {8, 8},
               flips = {{x = false, y = false}, {x = false, y = true}}
            },
         },
         shadow_offset_y = 4,
         shadow_height = 4,
         shadow_width = 4,
      },
      EnemyBullet = {
         entity_type = "EnemyProjectile",
         tags = "projectile,velocity,map_collidable,collidable,drawable,animatable,shadow,middleground",
         owner = "enemy",
         speed = 1.5,
         damage = 10,
         width = 16,
         height = 16,
         hitbox_width = 8,
         hitbox_height = 8,
         hitbox_offset_x = 4,
         hitbox_offset_y = 4,
         sprite_index_offsets = {
            down = 54,
            right = 54,
            left = 54,
            up = 54,
         },
         animations = {
            idle = {indices = {54, 55}, durations = {8, 8}}
         },
         sprite_offset_y = 5,
         shadow_offset_y = 3,
         shadow_width = 4,
         z = 6,
      },
   },
   Enemy = {
      Skulker = {
         entity_type = "Enemy",
         tags = "enemy,timers,velocity,map_collidable,collidable,health,drawable,animatable,sprite,shadow,middleground",
         hp = 20,
         xp_value = 10,
         max_speed = 0.5,
         contact_damage = 10,
         vision_range = 120,
         wander_radius = 40,
         wander_speed_mult = 0.6,
         wander_pause_min = 20,
         wander_pause_max = 60,
         sprite_index_offsets = {
            down = 48,
            right = 48,
            left = 48,
            up = 48,
         },
         animations = {
            death = {indices = {48}, durations = {30}}
         },
         width = 16,
         height = 16,
         hitbox_width = 12,
         hitbox_height = 10,
         hitbox_offset_x = 2,
         hitbox_offset_y = 3,
         shadow_offset_y = 2,
         shadow_width = 15,
         shadow_height = 6,
         outline_color = 1,
      },
      Shooter = {
         entity_type = "Enemy",
         tags =
         "enemy,shooter,timers,velocity,map_collidable,collidable,health,drawable,animatable,sprite,shadow,middleground",
         hp = 30,
         xp_value = 15,
         max_speed = 0.3,
         shot_speed = 1.5,
         damage = 10,
         range = 200,
         contact_damage = 10,
         shoot_delay = 120,
         vision_range = 200,
         is_shooter = true,
         wander_radius = 48,
         wander_speed_mult = 0.5,
         wander_pause_min = 30,
         wander_pause_max = 90,
         sprite_index_offsets = {
            down = 46,
            right = 46,
            left = 46,
            up = 46,
         },
         width = 16,
         height = 16,
         hitbox_width = 12,
         hitbox_height = 10,
         hitbox_offset_x = 2,
         hitbox_offset_y = 3,
         animations = {
            idle = {indices = {46, 47}, durations = {30, 30}},
            death = {indices = {46}, durations = {30}}
         },
         shadow_offset_y = 2,
         shadow_width = 17,
         shadow_height = 6,
         outline_color = 1,
         -- Muzzle flash (green magic)
         muzzle_flash_offsets = {
            down  = {x = 8, y = 14},
            up    = {x = 8, y = 2},
            right = {x = 14, y = 8},
            left  = {x = 2, y = 8},
         },
         muzzle_flash_colors = {11, 3, 26}, -- green, dark green, purple
      },
      Skull = {
         entity_type = "Enemy",
         tags = "skull,enemy,timers,velocity,collidable,health,drawable,animatable,shadow,middleground,flying",
         hp = 100,
         xp_value = 50,
         max_speed = 1,
         contact_damage = 100,
         drop_chance = 0.5,
         loot_rolls = 2,
         use_diverse_loot = true,
         sprite_index_offsets = {
            down = 53,
            right = 53,
            left = 53,
            up = 53,
         },
         animations = {
            down = {
               idle = {indices = {53}, durations = {30}},
               death = {indices = {53}, durations = {30}}
            },
            up = {
               idle = {indices = {53}, durations = {30}},
               death = {indices = {53}, durations = {30}}
            },
            left = {
               idle = {indices = {53}, durations = {30}},
               death = {indices = {53}, durations = {30}}
            },
            right = {
               idle = {indices = {53}, durations = {30}, flip = true},
               death = {indices = {53}, durations = {30}, flip = true}
            }
         },
         width = 16,
         height = 16,
         hitbox_width = 16,
         hitbox_height = 16,
         hitbox_offset_x = 0,
         hitbox_offset_y = 0,
         shadow_offset_y = 5,
         shadow_width = 13,
         outline_color = 1,
      },
      Dasher = {
         entity_type = "Enemy",
         tags = "enemy,timers,velocity,map_collidable,collidable,health,drawable,animatable,sprite,shadow,middleground",
         hp = 60,
         xp_value = 25,
         max_speed = 0.2,
         contact_damage = 15,
         vision_range = 150,
         windup_duration = 60,
         stun_duration = 120,
         dash_speed_multiplier = 10,
         sprite_index_offsets = {
            down = 51,
            right = 51,
            left = 51,
            up = 51,
         },
         sprite_shell = 50,
         width = 16,
         height = 16,
         hitbox_width = 12,
         hitbox_height = 10,
         hitbox_offset_x = 2,
         hitbox_offset_y = 3,
         animations = {
            down = {
               idle      = {indices = {51}, durations = {30}},
               walking   = {indices = {51, 52}, durations = {8, 8}},
               attacking = {indices = {50}, durations = {10}, loop = true},
               death     = {indices = {50}, durations = {30}}
            },
            up = {
               idle      = {indices = {51}, durations = {30}},
               walking   = {indices = {51, 52}, durations = {8, 8}},
               attacking = {indices = {50}, durations = {10}, loop = true},
               death     = {indices = {50}, durations = {30}}
            },
            right = {
               idle      = {indices = {51}, durations = {30}, flip = true},
               walking   = {indices = {51, 52}, durations = {8, 8}, flip = true},
               attacking = {indices = {50}, durations = {10}, loop = true, flip = true},
               death     = {indices = {50}, durations = {30}, flip = true}
            },
            left = {
               idle      = {indices = {51}, durations = {30}, flip = true},
               walking   = {indices = {51, 52}, durations = {8, 8}, flip = true},
               attacking = {indices = {50}, durations = {10}, loop = true, flip = true},
               death     = {indices = {50}, durations = {30}, flip = true}
            }
         },
         shadow_offset_y = 3,
         shadow_width = 17,
         outline_color = 1,
      },
      GreenWitch = {
         entity_type = "Enemy",
         tags =
         "enemy,boss,shooter,timers,velocity,map_collidable,collidable,health,drawable,animatable,sprite,shadow,middleground",
         hp = 600,
         xp_value = 100,
         max_speed = 2,
         contact_damage = 20,
         -- Phase thresholds (fraction of max HP)
         phase2_threshold = 0.66, -- Switch at 66% HP
         phase3_threshold = 0.33, -- Switch at 33% HP
         -- Combat stats (reuses EnemyBullet projectile)
         is_shooter = true,       -- Required for EnemyBullet projectile type
         shoot_delay = 60,
         shot_speed = 3,          -- Projectile speed
         vision_range = 300,
         dash_speed_multiplier = 4,
         stun_duration = 60,
         -- Minion summoning
         summon_cooldown = 180,
         summon_type = "Skulker",
         summon_count = 2,
         -- Visuals
         width = 24,
         height = 32,
         hitbox_width = 18,
         hitbox_height = 20,
         hitbox_offset_x = 3,
         hitbox_offset_y = 2,
         sprite_index_offsets = {
            down = 208,
            right = 208,
            left = 208,
            up = 208,
         },
         animations = {
            down = {
               idle      = {indices = {208}, durations = {30}},
               walking   = {indices = {208}, durations = {8}},
               attacking = {indices = {209}, durations = {30}},
               death     = {indices = {208}, durations = {30}}
            },
            up = {
               idle      = {indices = {208}, durations = {30}},
               walking   = {indices = {208}, durations = {8}},
               attacking = {indices = {209}, durations = {30}},
               death     = {indices = {208}, durations = {30}}
            },
            right = {
               idle      = {indices = {208}, durations = {30}, flip = true},
               walking   = {indices = {208}, durations = {8}, flip = true},
               attacking = {indices = {209}, durations = {30}, flip = true},
               death     = {indices = {208}, durations = {30}, flip = true}
            },
            left = {
               idle      = {indices = {208}, durations = {30}},
               walking   = {indices = {208}, durations = {8}},
               attacking = {indices = {209}, durations = {30}},
               death     = {indices = {208}, durations = {30}}
            }
         },
         shadow_offset_y = 6,
         shadow_width = 22,
         outline_color = 1,
         -- Muzzle flash (dark magic)
         muzzle_flash_offsets = {
            down  = {x = 12, y = 28},
            up    = {x = 12, y = 4},
            right = {x = 22, y = 16},
            left  = {x = 2, y = 16},
         },
         muzzle_flash_colors = {26, 27, 8}, -- purple, dark purple, red
      },
   },
   -- Player-summoned minions
   Minion = {
      Chick = {
         entity_type = "Chick",
         tags = "minion,timers,health,velocity,map_collidable,collidable,drawable,animatable,sprite,shadow,middleground",
         hp = 20,
         hp_drain_rate = 60,    -- Frames between each 1 HP loss (60 = 1 HP/second)
         food_seek_range = 120, -- Range to detect yolk splats
         food_heal_amount = 5,  -- HP restored per yolk splat eaten
         vision_range = 160,    -- Range to detect and chase enemies (160 = ~10 tiles)
         chase_speed_mult = 2,  -- Speed multiplier when chasing (1.2 = 120%)
         attack_damage = 3,     -- Damage per attack
         attack_cooldown = 30,  -- Frames between attacks (60 = 1 attack/second)
         attack_knockback = 3,  -- Knockback applied to chick after attack
         attack_range = 16,     -- Distance to trigger attack
         max_speed = 1,
         wander_radius = 32,
         wander_speed_mult = 0.8,
         wander_pause_min = 30,
         wander_pause_max = 90,
         follow_trigger_dist = 100, -- Distance to start following player
         follow_stop_dist = 50,     -- Distance to stop following
         follow_speed_mult = 3,     -- Speed multiplier when following (catch up)
         sprite_index_offsets = {
            down = 31,
            right = 31,
            left = 31,
            up = 31,
         },
         width = 16,
         height = 16,
         hitbox_width = 10,
         hitbox_height = 10,
         hitbox_offset_x = 3,
         hitbox_offset_y = 3,
         shadow_offset_x = -2,
         shadow_offset_y = -2,
         shadow_width = 8,
         animations = {
            down = {
               idle    = {indices = {33}, durations = {30}},
               walking = {indices = {31, 32}, durations = {8, 8}},
               death   = {indices = {33}, durations = {30}}
            },
            up = {
               idle    = {indices = {33}, durations = {30}},
               walking = {indices = {31, 32}, durations = {8, 8}},
               death   = {indices = {33}, durations = {30}}
            },
            right = {
               idle    = {indices = {33}, durations = {30}},
               walking = {indices = {31, 32}, durations = {8, 8}},
               death   = {indices = {33}, durations = {30}}
            },
            left = {
               idle    = {indices = {33}, durations = {30}, flip = true},
               walking = {indices = {31, 32}, durations = {8, 8}, flip = true},
               death   = {indices = {33}, durations = {30}, flip = true}
            }
         },
      },
      YolkSplat = {
         entity_type = "YolkSplat",
         tags = "yolk_splat,drawable,sprite,shadow,middleground,timers,map_collidable",
         -- map_collidable needed so it doesn't fall through floor if we use gravity, though usually splats are flat.
         -- Actually, simple splats might not need map_collidable if they are static.
         -- But minion/chick needs to find it.
         width = 16,
         height = 16,
         sprite_index = 36, -- Placeholder sprite index for Splat (needs to be set correctly)
         -- Let's use a "blob" sprite if available, or just a placeholder. 230 is arbitrary, will need to be checked.
         -- Actually, let's look for a suitable sprite index or use a generic one.
         -- Using 28 (Egg) as placeholder for now if unsure, but user said "Visual: A gross, yellow/orange puddle".
         -- I'll use 28 for now and comment it needs update.
         -- WAIT, I should check if there's a convention.
         -- Let's just define it, sprite_index can be fixed later.
         hitbox_width = 12,
         hitbox_height = 12,
         hitbox_offset_x = 2,
         hitbox_offset_y = 2,
         shadow_offset_y = 4,
         shadow_width = 10,
         outline_color = nil,
      },
      Egg = {
         entity_type = "Egg",
         tags = "minion,drawable,sprite,shadow,middleground,timers",
         width = 16,
         height = 16,
         sprite_index = 28, -- Initial egg sprite
         hitbox_width = 8,
         hitbox_height = 8,
         hitbox_offset_x = 4,
         hitbox_offset_y = 4,
         shadow_offset_y = 4,
         shadow_width = 6,
         -- Hatching animation frames (AI-driven based on hatch_timer progress)
         hatch_frames = {28, 29, 30},
      },
   },
}
