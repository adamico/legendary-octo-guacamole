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
         hitbox = {
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
         sprite_offset_y = 4,
         animations = {
            down = {
               indices = {26, 26},
               durations = {8, 8},
               flips = {
                  {x = false, y = false}, {x = true, y = false}
               }
            },
            up = {
               indices = {26, 26},
               durations = {8, 8},
               flips = {
                  {x = false, y = false}, {x = true, y = false}
               }
            },
            right = {
               indices = {25, 25},
               durations = {8, 8},
               flips = {
                  {x = false, y = false}, {x = false, y = true}
               }
            },
            left = {
               indices = {25, 25},
               durations = {8, 8},
               flips = {
                  {x = false, y = false}, {x = false, y = true}
               }
            },
         },
         shadow_offsets_y = {
            down = 8,
            up = 8,
            right = 16,
            left = 2,
         },
         shadow_heights = {
            down = 12,
            up = 12,
            right = 2,
            left = 2,
         },
         shadow_widths = {
            down = 2,
            up = 2,
            right = 12,
            left = 12,
         },
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
            down = 25,
            right = 25,
            left = 25,
            up = 25,
         },
         animations = {
            idle = {indices = {25, 26}, durations = {8, 8}}
         },
         sprite_offset_y = 5,
         shadow_offset_y = 3,
         shadow_width = 4,
         z = 6,
      },
   },
   Pickup = {
      ProjectilePickup = {
         entity_type = "ProjectilePickup",
         tags = "pickup,velocity,collidable,drawable,sprite,background,shadow",
         pickup_effect = "health",
         width = 16,
         height = 16,
         hitbox_from_projectile = true,
         sprite_index_offsets = {
            down = 20,
            right = 19,
            left = 19,
            up = 20,
         },
         sprite_offset_y = 6,
         shadow_offset_y = 4,
         shadow_width = 6,
      },
      HealthPickup = {
         entity_type = "HealthPickup",
         tags = "pickup,collidable,drawable,sprite,background,shadow",
         pickup_effect = "health",
         width = 16,
         height = 16,
         sprite_index = 21,
         hitbox_width = 12,
         hitbox_height = 12,
         hitbox_offset_x = 2,
         hitbox_offset_y = 2,
         shadow_offset_y = 3,
         shadow_width = 11,
         recovery_amount = 20,
      },
      Coin = {
         entity_type = "Coin",
         tags = "pickup,collidable,drawable,sprite,background,shadow",
         pickup_effect = "coin",
         width = 16,
         height = 16,
         sprite_index = 24,
         hitbox_width = 12,
         hitbox_height = 12,
         hitbox_offset_x = 2,
         hitbox_offset_y = 2,
         shadow_offset_y = 3,
         shadow_width = 11,
         amount = 1,
      },
      Key = {
         entity_type = "Key",
         tags = "pickup,collidable,drawable,sprite,background,shadow",
         pickup_effect = "key",
         width = 16,
         height = 16,
         sprite_index = 23,
         hitbox_width = 12,
         hitbox_height = 12,
         hitbox_offset_x = 2,
         hitbox_offset_y = 2,
         shadow_offset_y = 3,
         shadow_width = 11,
         amount = 1,
      },
      Bomb = {
         entity_type = "Bomb",
         tags = "pickup,collidable,drawable,sprite,background,shadow",
         pickup_effect = "bomb",
         width = 16,
         height = 16,
         sprite_index = 22,
         hitbox_width = 12,
         hitbox_height = 12,
         hitbox_offset_x = 2,
         hitbox_offset_y = 2,
         shadow_offset_y = 3,
         shadow_width = 11,
         amount = 1,
      },
   },
   Enemy = {
      Skulker = {
         entity_type = "Enemy",
         tags = "enemy,timers,velocity,map_collidable,collidable,health,drawable,animatable,sprite,shadow,middleground",
         hp = 20,
         max_speed = 0.5,
         contact_damage = 10,
         vision_range = 120,
         wander_radius = 40,
         wander_speed_mult = 0.6,
         wander_pause_min = 20,
         wander_pause_max = 60,
         sprite_index_offsets = {
            down = 35,
            right = 35,
            left = 35,
            up = 35,
         },
         animations = {
            death = {indices = {35}, durations = {30}}
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
            down = 33,
            right = 33,
            left = 33,
            up = 33,
         },
         width = 16,
         height = 16,
         hitbox_width = 12,
         hitbox_height = 10,
         hitbox_offset_x = 2,
         hitbox_offset_y = 3,
         animations = {
            idle = {indices = {33, 34}, durations = {30, 30}},
            death = {indices = {33}, durations = {30}}
         },
         shadow_offset_y = 2,
         shadow_width = 17,
         shadow_height = 6,
         outline_color = 1,
      },
      Skull = {
         entity_type = "Enemy",
         tags = "skull,enemy,timers,velocity,collidable,health,drawable,animatable,shadow,middleground,flying",
         hp = 100,
         max_speed = 0.6,
         contact_damage = 100,
         drop_chance = 0.5,
         loot_rolls = 2,
         use_diverse_loot = true,
         sprite_index_offsets = {
            down = 40,
            right = 40,
            left = 40,
            up = 40,
         },
         animations = {
            down = {
               idle = {indices = {40}, durations = {30}},
               death = {indices = {40}, durations = {30}}
            },
            up = {
               idle = {indices = {40}, durations = {30}},
               death = {indices = {40}, durations = {30}}
            },
            left = {
               idle = {indices = {40}, durations = {30}},
               death = {indices = {40}, durations = {30}}
            },
            right = {
               idle = {indices = {40}, durations = {30}, flip = true},
               death = {indices = {40}, durations = {30}, flip = true}
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
         max_speed = 0.2,
         contact_damage = 15,
         vision_range = 150,
         windup_duration = 60,
         stun_duration = 120,
         dash_speed_multiplier = 10,
         sprite_index_offsets = {
            down = 38,
            right = 38,
            left = 38,
            up = 38,
         },
         sprite_shell = 37,
         width = 16,
         height = 16,
         hitbox_width = 12,
         hitbox_height = 10,
         hitbox_offset_x = 2,
         hitbox_offset_y = 3,
         animations = {
            down = {
               idle      = {indices = {38}, durations = {30}},
               walking   = {indices = {38, 39}, durations = {8, 8}},
               attacking = {indices = {37}, durations = {10}, loop = true},
               death     = {indices = {37}, durations = {30}}
            },
            up = {
               idle      = {indices = {38}, durations = {30}},
               walking   = {indices = {38, 39}, durations = {8, 8}},
               attacking = {indices = {37}, durations = {10}, loop = true},
               death     = {indices = {37}, durations = {30}}
            },
            right = {
               idle      = {indices = {38}, durations = {30}},
               walking   = {indices = {38, 39}, durations = {8, 8}},
               attacking = {indices = {37}, durations = {10}, loop = true},
               death     = {indices = {37}, durations = {30}}
            },
            left = {
               idle      = {indices = {38}, durations = {30}, flip = true},
               walking   = {indices = {38, 39}, durations = {8, 8}, flip = true},
               attacking = {indices = {37}, durations = {10}, loop = true, flip = true},
               death     = {indices = {37}, durations = {30}, flip = true}
            }
         },
         shadow_offset_y = 3,
         shadow_width = 17,
         outline_color = 1,
      },
   },
   -- Player-summoned minions
   Minion = {
      Chick = {
         entity_type = "Chick",
         tags = "minion,velocity,map_collidable,drawable,animatable,sprite,shadow,middleground",
         hp = 1,
         max_speed = 0.3,
         wander_radius = 32,
         wander_speed_mult = 0.8,
         wander_pause_min = 30,
         wander_pause_max = 90,
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
   },
   Obstacle = {
      Rock = {
         entity_type = "Rock",
         obstacle = true,
         tags = "obstacle,collidable,drawable,sprite,world_obj,middleground,static",
         width = 16,
         height = 16,
         hitbox_width = 16,
         hitbox_height = 16,
         hitbox_offset_x = 4,
         hitbox_offset_y = 4,
         outline_color = nil,
      },
      Destructible = {
         entity_type = "Destructible",
         obstacle = true,
         destructible = true,
         tags = "obstacle,collidable,drawable,sprite,world_obj,destructible,middleground,static",
         hp = 1,
         width = 16,
         height = 16,
         hitbox_width = 16,
         hitbox_height = 16,
         hitbox_offset_x = 4,
         hitbox_offset_y = 4,
         outline_color = nil,
      },
   },
}
