SCREEN_WIDTH = 480
SCREEN_HEIGHT = 270
GRID_SIZE = 16
SOLID_FLAG = 0

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
      damage = 10,
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
   ProjectilePickup = {
      sprite_index_offsets = {
         down = 78,
         right = 77,
         left = 77,
         up = 78,
      },
   },
   EnemyProjectile = {
      damage = 10,
      speed = 1.5,
      hitbox_width = 8,
      hitbox_height = 8,
      hitbox_offset_x = 4,
      hitbox_offset_y = 4,
      animations = {
         idle = {indices = {71, 72}, durations = {8, 8}}
      },
      sprite_offset_y = -5,
      shadow_offset = 3,
      shadow_width = 4,
   },
   Enemy = {
      Skulker = {
         hp = 20,
         speed = 0.5,
         contact_damage = 10,
         sprite_index_offsets = {
            down = 231,
            right = 231,
            left = 231,
            up = 231,
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
         hp = 30,
         speed = 0.3,
         contact_damage = 10,
         shoot_delay = 120,
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
            idle = {indices = {225, 226}, durations = {30, 30}}
         },
         shadow_offset = 3,
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
