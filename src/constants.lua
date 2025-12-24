SCREEN_WIDTH = 480
SCREEN_HEIGHT = 270
GRID_SIZE = 16
SOLID_FLAG = 0
SPRITE_DOOR_OPEN = 0
SPRITE_DOOR_BLOCKED = 6
TRANSITION_TRIGGER_TILE = 24
SKULL_SPAWN_TIMER = 420

local GameConstants = {
   Player = {
      invulnerable_time = 120, -- frames
      move_speed = vec(1, 1),
      width = 16,
      height = 16,
      hitbox_width = 10,
      hitbox_height = 12,
      hitbox_offset_x = 3,
      hitbox_offset_y = 4,
      max_health = 100,
      shot_cost = 20,
      recovery_percent = 0.8,
      regen_rate = 15,
      regen_delay = 1.5,
      animations = {
         down = {
            idle      = {indices = {238, 239}, durations = {30, 30}},
            walking   = {top_indices = {240}, bottom_indices = {240, 255}, durations = {8, 8}, split_row = 9},
            attacking = {indices = {241, 242}, durations = {4, 22}},
            hurt      = {indices = {243}, durations = {30}},
            death     = {indices = {244}, durations = {8}}
         },
         right = {
            idle      = {indices = {246, 247}, durations = {30, 30}},
            walking   = {indices = {248, 249}, durations = {8, 8}},
            attacking = {indices = {250, 251}, durations = {4, 22}},
            hurt      = {indices = {252}, durations = {30}},
            death     = {indices = {244}, durations = {8}}
         },
         up = {
            idle      = {indices = {253, 254}, durations = {30, 30}},
            walking   = {top_indices = {255}, bottom_indices = {255, 240}, durations = {8, 8}, split_row = 9},
            attacking = {indices = {253}, durations = {8, 22}},
            hurt      = {indices = {253}, durations = {30}},
            death     = {indices = {244}, durations = {8}}
         },
         left = {
            idle      = {indices = {246, 247}, durations = {30, 30}, flip = true},
            walking   = {indices = {248, 249}, durations = {8, 8}, flip = true},
            attacking = {indices = {250, 251}, durations = {4, 22}, flip = true},
            hurt      = {indices = {252}, durations = {30}, flip = true},
            death     = {indices = {244}, durations = {8}, flip = true}
         }
      },
      sprite_index_offsets = {
         down = 238,
         right = 246,
         left = 246,
         up = 253,
      },
      shadow_offset = 0,
   },
   Projectile = {
      -- Player's laser projectile
      Laser = {
         entity_type = "Projectile",
         tags = "projectile,velocity,map_collidable,collidable,drawable,animatable,palette_swappable,shadow,middleground",
         owner = "player",
         speed = 4,
         damage = 20,
         width = 16,
         height = 16,
         hitbox = {
            down  = {w = 6, h = 12, ox = 4, oy = 4},
            up    = {w = 6, h = 12, ox = 4, oy = 2},
            right = {w = 10, h = 6, ox = 3, oy = 5},
            left  = {w = 10, h = 6, ox = 3, oy = 5},
         },
         sprite_index_offsets = {
            down = 78,
            right = 77,
            left = 77,
            up = 78,
         },
         sprite_offset_y = 0,
         animations = {
            down = {
               indices = {78, 78},
               durations = {8, 8},
               flips = {
                  {x = false, y = false}, {x = true, y = false}
               }
            },
            up = {
               indices = {78, 78},
               durations = {8, 8},
               flips = {
                  {x = false, y = false}, {x = true, y = false}
               }
            },
            right = {
               indices = {77, 77},
               durations = {8, 8},
               flips = {
                  {x = false, y = false}, {x = false, y = true}
               }
            },
            left = {
               indices = {77, 77},
               durations = {8, 8},
               flips = {
                  {x = false, y = false}, {x = false, y = true}
               }
            },
         },
         palette_swaps = {
            {from = 5, to = 12},
         },
         shadow_offsets = {
            down = 8,
            up = 8,
            right = 2,
            left = 2,
         },
         shadow_widths = {
            down = 6,
            up = 6,
            right = 10,
            left = 10,
         },
      },
      -- Enemy bullet projectile
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
            down = 71,
            right = 71,
            left = 71,
            up = 71,
         },
         animations = {
            idle = {indices = {71, 72}, durations = {8, 8}}
         },
         sprite_offset_y = -5,
         shadow_offset = 3,
         shadow_width = 4,
      },
   },
   Pickup = {
      -- Pickup spawned when player projectile hits wall (recoverable health)
      ProjectilePickup = {
         entity_type = "ProjectilePickup",
         tags = "pickup,collidable,drawable,sprite,background",
         pickup_effect = "health",
         width = 16,
         height = 16,
         -- Uses direction-based hitbox from Projectile.Laser
         hitbox_from_projectile = true,
         sprite_index_offsets = {
            down = 78,
            right = 77,
            left = 77,
            up = 78,
         },
      },
      -- Health pickup spawned when enemies die
      HealthPickup = {
         entity_type = "HealthPickup",
         tags = "pickup,collidable,drawable,sprite,background",
         pickup_effect = "health",
         width = 16,
         height = 16,
         sprite_index = 64,
         hitbox_width = 12,
         hitbox_height = 12,
         hitbox_offset_x = 2,
         hitbox_offset_y = 2,
      },
   },
   Enemy = {
      Skulker = {
         entity_type = "Enemy",
         tags = "enemy,velocity,map_collidable,collidable,health,drawable,animatable,sprite,shadow,middleground",
         hp = 20,
         speed = 0.5,
         contact_damage = 10,
         sprite_index_offsets = {
            down = 231,
            right = 231,
            left = 231,
            up = 231,
         },
         animations = {
            death = {indices = {231}, durations = {30}}
         },
         width = 16,
         height = 16,
         hitbox_width = 12,
         hitbox_height = 10,
         hitbox_offset_x = 2,
         hitbox_offset_y = 3,
         shadow_offset = 2,
         shadow_width = 12,
      },
      Shooter = {
         entity_type = "Enemy",
         tags = "enemy,velocity,map_collidable,collidable,health,drawable,animatable,sprite,shadow,middleground",
         hp = 30,
         speed = 0.3,
         contact_damage = 10,
         shoot_delay = 120,
         is_shooter = true,
         sprite_index_offsets = {
            down = 225,
            right = 225,
            left = 225,
            up = 225,
         },
         width = 16,
         height = 16,
         hitbox_width = 12,
         hitbox_height = 10,
         hitbox_offset_x = 2,
         hitbox_offset_y = 3,
         animations = {
            idle = {indices = {225, 226}, durations = {30, 30}},
            death = {indices = {225}, durations = {30}}
         },
         shadow_offset = 3,
         shadow_width = 12,
      },
      Skull = {
         entity_type = "Skull",
         tags = "skull,enemy,velocity,collidable,health,drawable,sprite,shadow,middleground",
         hp = 1,
         speed = 0.6,
         contact_damage = 20,
         sprite_index_offsets = {
            down = 117,
            right = 117,
            left = 117,
            up = 117,
         },
         width = 16,
         height = 16,
         hitbox_width = 16,
         hitbox_height = 16,
         hitbox_offset_x = 0,
         hitbox_offset_y = 0,
         shadow_offset = 0,
         shadow_width = 13,
      },
      Dasher = {
         entity_type = "Enemy",
         tags = "enemy,velocity,map_collidable,collidable,health,drawable,animatable,sprite,shadow,middleground",
         hp = 60,                    -- Higher HP (tank)
         speed = 0.2,                -- Very slow base speed
         contact_damage = 15,
         vision_range = 100,         -- Same as Shooter's target distance
         windup_duration = 60,       -- Frames before dash
         stun_duration = 120,        -- Frames of stun after collision
         dash_speed_multiplier = 10, -- 10x base speed during dash
         sprite_index_offsets = {
            down = 236,
            right = 236,
            left = 236,
            up = 236,
         },
         sprite_shell = 235, -- Shell sprite during dash
         width = 16,
         height = 16,
         hitbox_width = 12,
         hitbox_height = 10,
         hitbox_offset_x = 2,
         hitbox_offset_y = 3,
         animations = {
            down = {
               idle      = {indices = {236}, durations = {30}},
               walking   = {indices = {236, 237}, durations = {8, 8}},
               attacking = {indices = {235}, durations = {10}, loop = true},
               death     = {indices = {235}, durations = {30}}
            },
            up = {
               idle      = {indices = {236}, durations = {30}},
               walking   = {indices = {236, 237}, durations = {8, 8}},
               attacking = {indices = {235}, durations = {10}, loop = true},
               death     = {indices = {235}, durations = {30}}
            },
            right = {
               idle      = {indices = {236}, durations = {30}},
               walking   = {indices = {236, 237}, durations = {8, 8}},
               attacking = {indices = {235}, durations = {10}, loop = true},
               death     = {indices = {235}, durations = {30}}
            },
            left = {
               idle      = {indices = {236}, durations = {30}, flip = true},
               walking   = {indices = {236, 237}, durations = {8, 8}, flip = true},
               attacking = {indices = {235}, durations = {10}, loop = true, flip = true},
               death     = {indices = {235}, durations = {30}, flip = true}
            }
         },
         shadow_offset = 2,
         shadow_width = 12,
      },
      drop_chance = 1.0,
   },
   title = "Pizak",
   score = {
   },
   debug = {
      show_hitboxes = false,
      show_attributes = false,
   },
   cheats = {
      noclip = false,
      godmode = false,
   },
   buttons = {
      -- first stick
      left = 0,
      right = 1,
      up = 2,
      down = 3,
      o = 4,
      x = 5,
      menu = 6,
      reserved = 7,
      -- second stick
      left2 = 8,
      right2 = 9,
      up2 = 10,
      down2 = 11,
      o2 = 12,
      x2 = 13,
      sl2 = 14,
      sr2 = 15,
   }
}

GameConstants.controls = {
   move_up = GameConstants.buttons.up,
   move_down = GameConstants.buttons.down,
   move_left = GameConstants.buttons.left,
   move_right = GameConstants.buttons.right,
   shoot_up = GameConstants.buttons.up2,
   shoot_down = GameConstants.buttons.down2,
   shoot_left = GameConstants.buttons.left2,
   shoot_right = GameConstants.buttons.right2,
}

return GameConstants
