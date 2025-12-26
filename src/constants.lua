SCREEN_WIDTH = 480
SCREEN_HEIGHT = 270
GRID_SIZE = 16
SOLID_FLAG = 0
EMPTY_TILE = 0
DOOR_OPEN_TILE = 86
DOOR_BLOCKED_TILE = 71
WALL_TILE = 140
-- Lighting and Shadow constants
LIGHTING_SPOTLIGHT_COLOR = 33
LIGHTING_SHADOW_COLOR = 32

-- Autotiling constants
WALL_TILE_CORNER_TL = 64                             -- A: top-left corner
WALL_TILE_CORNER_TR = 68                             -- B: top-right corner
WALL_TILE_CORNER_BL = 96                             -- C: bottom-left corner
WALL_TILE_CORNER_BR = 100                            -- D: bottom-right corner
WALL_TILE_HORIZONTAL = {65, 66, 67, 97, 98, 99, 121} -- H: horizontal wall variants
WALL_TILE_VERTICAL = {72, 80, 88, 76, 84, 92}        -- V: vertical wall variants
-- Inner corner tiles (for walls between adjacent rooms with 2 diagonal floors)
WALL_TILE_INNER_TOP = 137                            -- 2 diagonals on top (TL + TR): inner corner pointing down
WALL_TILE_INNER_BOTTOM = 145                         -- 2 diagonals on bottom (BL + BR): inner corner pointing up
WALL_TILE_INNER_RIGHT = 116                          -- 2 diagonals on right (TR + BR): inner corner pointing left
WALL_TILE_INNER_LEFT = 115                           -- 2 diagonals on left (TL + BL): inner corner pointing right
FLOOR_TILES = {73, 74, 75, 81, 82, 83, 89, 90, 91}   -- F: floor variants
-- Door frame tiles
DOOR_FRAME_H_TOP = {77, 93, 123, 124, 148, 153}      -- Horizontal door top frame
DOOR_FRAME_H_BOTTOM = {107, 108, 129, 132}           -- Horizontal door bottom frame
DOOR_FRAME_V_LEFT = {117, 122, 138, 141, 146}        -- Vertical door left frame
DOOR_FRAME_V_RIGHT = {114, 120, 136, 139, 144}       -- Vertical door right frame

-- Collision system constants
TILE_EDGE_TOLERANCE = 0.001    -- Small buffer to prevent floating-point edge cases when checking tile boundaries
DOOR_GUIDANCE_MULTIPLIER = 1.5 -- Speed multiplier for nudging player toward nearby unlocked doors
SPATIAL_GRID_CELL_SIZE = 64    -- Spatial partitioning cell size in pixels (4 tiles) for collision optimization

SKULL_SPAWN_TIMER = 420
SKULL_SPAWN_LOCKED_TIMER = 1800

local GameConstants = {
   Player = {
      invulnerable_time = 120, -- frames
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
            idle      = {indices = {1, 2}, durations = {30, 30}},
            walking   = {top_indices = {3}, bottom_indices = {3, 18}, durations = {8, 8}, split_row = 9},
            attacking = {indices = {4, 5}, durations = {4, 22}},
            hurt      = {indices = {6}, durations = {30}},
            death     = {indices = {7}, durations = {8}}
         },
         right = {
            idle      = {indices = {9, 10}, durations = {30, 30}},
            walking   = {indices = {11, 12}, durations = {8, 8}},
            attacking = {indices = {13, 14}, durations = {4, 22}},
            hurt      = {indices = {15}, durations = {30}},
            death     = {indices = {7}, durations = {8}}
         },
         up = {
            idle      = {indices = {16, 17}, durations = {30, 30}},
            walking   = {top_indices = {18}, bottom_indices = {18, 3}, durations = {8, 8}, split_row = 9},
            attacking = {indices = {16}, durations = {8, 22}},
            hurt      = {indices = {6}, durations = {30}},
            death     = {indices = {7}, durations = {8}}
         },
         left = {
            idle      = {indices = {9, 10}, durations = {30, 30}, flip = true},
            walking   = {indices = {11, 12}, durations = {8, 8}, flip = true},
            attacking = {indices = {13, 14}, durations = {4, 22}, flip = true},
            hurt      = {indices = {15}, durations = {30}, flip = true},
            death     = {indices = {7}, durations = {8}, flip = true}
         }
      },
      sprite_index_offsets = {
         down = 1,
         right = 9,
         left = 9,
         up = 16,
      },
      shadow_offset = 1,
      shadow_width = 13,
      outline_color = 1,
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
            down = 19,
            right = 20,
            left = 20,
            up = 19,
         },
         sprite_offset_y = 0,
         animations = {
            down = {
               indices = {20, 20},
               durations = {8, 8},
               flips = {
                  {x = false, y = false}, {x = true, y = false}
               }
            },
            up = {
               indices = {20, 20},
               durations = {8, 8},
               flips = {
                  {x = false, y = false}, {x = true, y = false}
               }
            },
            right = {
               indices = {19, 19},
               durations = {8, 8},
               flips = {
                  {x = false, y = false}, {x = false, y = true}
               }
            },
            left = {
               indices = {19, 19},
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
            down = 25,
            right = 25,
            left = 25,
            up = 25,
         },
         animations = {
            idle = {indices = {25, 26}, durations = {8, 8}}
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
         tags = "pickup,collidable,drawable,sprite,background,shadow",
         pickup_effect = "health",
         width = 16,
         height = 16,
         -- Uses direction-based hitbox from Projectile.Laser
         hitbox_from_projectile = true,
         sprite_index_offsets = {
            down = 20,
            right = 19,
            left = 19,
            up = 20,
         },
         shadow_offset = 2,
         shadow_width = 6,
      },
      -- Health pickup spawned when enemies die
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
         shadow_offset = 3,
         shadow_width = 11,
      },
   },
   Enemy = {
      Skulker = {
         entity_type = "Enemy",
         tags = "enemy,velocity,map_collidable,collidable,health,drawable,animatable,sprite,shadow,middleground",
         hp = 20,
         speed = 0.5,
         contact_damage = 10,
         vision_range = 120,
         -- Wandering configuration
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
         shadow_offset = 3,
         shadow_width = 15,
         outline_color = 1,
      },
      Shooter = {
         entity_type = "Enemy",
         tags =
         "enemy,shooter,timers,velocity,map_collidable,collidable,health,drawable,animatable,sprite,shadow,middleground",
         hp = 30,
         speed = 0.3,
         contact_damage = 10,
         shoot_delay = 120,
         vision_range = 200,
         is_shooter = true,
         -- Wandering configuration
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
         shadow_offset = 4,
         shadow_width = 17,
         outline_color = 1,
      },
      Skull = {
         entity_type = "Skull",
         tags = "skull,enemy,velocity,collidable,health,drawable,sprite,shadow,middleground",
         hp = 1,
         speed = 0.6,
         contact_damage = 20,
         sprite_index_offsets = {
            down = 40,
            right = 40,
            left = 40,
            up = 40,
         },
         width = 16,
         height = 16,
         hitbox_width = 16,
         hitbox_height = 16,
         hitbox_offset_x = 0,
         hitbox_offset_y = 0,
         shadow_offset = 5,
         shadow_width = 13,
         outline_color = 1,
      },
      Dasher = {
         entity_type = "Enemy",
         tags = "enemy,velocity,map_collidable,collidable,health,drawable,animatable,sprite,shadow,middleground",
         hp = 60,                    -- Higher HP (tank)
         speed = 0.2,                -- Very slow base speed
         contact_damage = 15,
         vision_range = 150,         -- Increased by 50% (was 100)
         windup_duration = 60,       -- Frames before dash
         stun_duration = 120,        -- Frames of stun after collision
         dash_speed_multiplier = 10, -- 10x base speed during dash
         sprite_index_offsets = {
            down = 38,
            right = 38,
            left = 38,
            up = 38,
         },
         sprite_shell = 37, -- Shell sprite during dash
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
         shadow_offset = 3,
         shadow_width = 17,
         outline_color = 1,
      },
   },
   Emotions = {
      alert = {text = "!", color = 8, duration = 60}, -- red "!" when spotting player
      confused = {text = "?", color = 12, duration = 90}, -- cyan "?" when losing player
      idle = {text = "♪", color = 11, duration = 120}, -- green "♪" when wandering
      stunned = {text = "★", color = 10, duration = 90}, -- yellow "★" when stunned
      offset_y = -18, -- Vertical offset above entity (was -10)
      bounce_speed = 0.15, -- Bounce animation speed
      bounce_height = 2, -- Bounce amplitude in pixels
      outline_color = 0, -- Black outline for visibility
   },
   title = "Pizak",
   debug = {
      show_hitboxes = false,
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

-- Collision layers (bitmasking for fast collision filtering)
GameConstants.CollisionLayers = {
   PLAYER = 1,            -- 0b000001
   ENEMY = 2,             -- 0b000010
   PLAYER_PROJECTILE = 4, -- 0b000100
   ENEMY_PROJECTILE = 8,  -- 0b001000
   PICKUP = 16,           -- 0b010000
   WORLD = 32,            -- 0b100000
}

-- What each layer can collide with (bitmask)
GameConstants.CollisionMasks = {
   [1] = 2 + 8 + 16 + 32, -- PLAYER: Enemy + EnemyProjectile + Pickup + World
   [2] = 1 + 4 + 32,      -- ENEMY: Player + PlayerProjectile + World
   [4] = 2 + 32,          -- PLAYER_PROJECTILE: Enemy + World
   [8] = 1 + 32,          -- ENEMY_PROJECTILE: Player + World
   [16] = 1,              -- PICKUP: Player only
   [32] = 1 + 2 + 4 + 8,  -- WORLD: Everything except Pickup
}

-- Entity type to collision layer mapping
GameConstants.EntityCollisionLayer = {
   Player = GameConstants.CollisionLayers.PLAYER,
   Enemy = GameConstants.CollisionLayers.ENEMY,
   Skull = GameConstants.CollisionLayers.ENEMY,
   Projectile = GameConstants.CollisionLayers.PLAYER_PROJECTILE,
   EnemyProjectile = GameConstants.CollisionLayers.ENEMY_PROJECTILE,
   ProjectilePickup = GameConstants.CollisionLayers.PICKUP,
   HealthPickup = GameConstants.CollisionLayers.PICKUP,
}

return GameConstants
