SCREEN_WIDTH = 480
SCREEN_HEIGHT = 270
GRID_SIZE = 16
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

-- Room feature tiles (for layout carving)
ROCK_TILES = {134, 135, 142, 143}         -- R: solid rock obstacles
PIT_TILE = 85                             -- P: pit (blocks walking, not projectiles)
DESTRUCTIBLE_TILES = {150, 151, 158, 159} -- D: breakable obstacles

-- Feature type flags (for collision logic)
SOLID_FLAG = 0
FEATURE_FLAG_PIT = 1 -- allows projectiles to pass

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
      max_hp_to_shot_cost_ratio = 0.2,
      recovery_percent = 0.8,
      regen_rate = 0,
      regen_delay = 1.5,
      -- Stats
      max_speed = 2,                -- Movement speed
      shot_speed = 4,
      max_hp_to_damage_ratio = 0.2, -- Damage = max_hp * ratio
      range = 200,                  -- Max distance in pixels
      fire_rate = 15,               -- Frames between shots (was shoot_cooldown_duration)
      base_knockback = 4,           -- Base knockback applied to all player attacks
      vampiric_heal = 0.3,          -- Heal player for 30% of damage dealt
      -- Inventory
      coins = 0,
      keys = 0,
      bombs = 2,
      animations = {
         down = {
            idle      = {indices = {1, 2}, durations = {30, 30}},
            walking   = {top_indices = {3}, bottom_indices = {3, 18}, durations = {8, 8}, split_row = 9},
            attacking = {indices = {4, 5}, durations = {4, 15}},
            hurt      = {indices = {6}, durations = {30}},
            death     = {indices = {7}, durations = {8}}
         },
         right = {
            idle      = {indices = {9, 10}, durations = {30, 30}},
            walking   = {indices = {11, 12}, durations = {8, 8}},
            attacking = {indices = {13, 14}, durations = {4, 15}},
            hurt      = {indices = {15}, durations = {30}},
            death     = {indices = {7}, durations = {8}}
         },
         up = {
            idle      = {indices = {16, 17}, durations = {30, 30}},
            walking   = {top_indices = {18}, bottom_indices = {18, 3}, durations = {8, 8}, split_row = 9},
            attacking = {indices = {16}, durations = {8, 15}},
            hurt      = {indices = {6}, durations = {30}},
            death     = {indices = {7}, durations = {8}}
         },
         left = {
            idle      = {indices = {9, 10}, durations = {30, 30}, flip = true},
            walking   = {indices = {11, 12}, durations = {8, 8}, flip = true},
            attacking = {indices = {13, 14}, durations = {4, 15}, flip = true},
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
      shadow_offset_x = 0,
      shadow_offset_y = -1,
      shadow_width = 15,
      shadow_height = 6,
      outline_color = 1,
      melee_cost = 10,
      melee_cooldown = 60,
      melee_sprite = 31,
      melee_range = 14,
      melee_hitboxes = {
         down  = {w = 14, h = 16, ox = 4, oy = -4},
         up    = {w = 12, h = 12, ox = 3, oy = 4},
         right = {w = 16, h = 12, ox = -6, oy = 4},
         left  = {w = 16, h = 12, ox = 4, oy = 4},
      },
      melee_width = 9,
      melee_height = 16,
      melee_duration = 15,
      melee_knockback = 6,
   },
   Projectile = {
      Laser = {
         entity_type = "Projectile",
         tags = "projectile,velocity,map_collidable,collidable,drawable,animatable,palette_swappable,shadow,middleground",
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
            down = 19,
            right = 20,
            left = 20,
            up = 19,
         },
         sprite_offset_y = 6,
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
         shadow_offsets_y = {
            down = 8,
            up = 8,
            right = 2,
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
   -- Placed bomb entity (not the pickup)
   PlacedBomb = {
      entity_type = "PlacedBomb",
      tags = "bomb,drawable,sprite,timers,shadow,middleground",
      width = 16,
      height = 16,
      sprite_index = 22, -- Bomb placed sprite
      sprite_index_offsets = {
         down = 22,
         up = 22,
         left = 22,
         right = 22,
      },
      fuse_time = 180,      -- 3 seconds at 60fps
      explosion_radius = 1, -- 1 tile = 3x3 grid centered on bomb
      shadow_offset_y = 3,
      shadow_width = 12,
   },
   -- Explosion effect entity (reusable for bombs, enemy attacks, etc.)
   Explosion = {
      entity_type = "Explosion",
      tags = "explosion,collidable,drawable,sprite,timers,middleground",
      width = 16,
      height = 16,
      sprite_index = 27,
      sprite_index_offsets = {
         down = 27,
         up = 27,
         left = 27,
         right = 27,
      },
      hitbox_width = 14,
      hitbox_height = 14,
      hitbox_offset_x = 1,
      hitbox_offset_y = 1,
      lifespan = 30,
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
   FloatingText = {
      rise_speed = 0.5,   -- Pixels per frame to rise
      duration = 45,      -- Total frames before removal
      fade_duration = 15, -- Frames for fade out (part of total duration)
      damage_color = 8,   -- Red for damage
      heal_color = 11,    -- Green for healing
      pickup_color = 10,  -- Yellow for pickups
      outline_color = 0,  -- Black outline for visibility
      offset_y = -8,      -- Initial vertical offset from entity top
      spread = 8,         -- Horizontal spread for multiple texts
   },
   Hud = {
      inventory = {
         x = 10,             -- Base X position from left
         y = 16,             -- Base Y position from top (below health bar)
         spacing_y = 16,     -- Vertical spacing between items
         icon_size = 11,     -- Size of icons
         text_offset_x = 16, -- Text distance from icon left
         text_offset_y = 2,  -- Text vertical alignment
         text_color = 7,     -- White text
         shadow_color = 1,   -- Black shadow/outline
         sprites = {
            coins = 197,
            bombs = 196,
            keys = 198,
         }
      },
   },
   Minimap = {
      cell_size = 11,        -- Size of each room cell in pixels (10x10 sprite + padding)
      padding = 1,           -- Padding between cells
      margin_x = 26,         -- Distance from right screen edge
      margin_y = 24,         -- Distance from top screen edge (default position)
      margin_y_bottom = 24,  -- Distance from bottom screen edge (alternate position)
      viewport_w = 5,        -- Max visible rooms horizontally
      viewport_h = 5,        -- Max visible rooms vertically
      border_color = 5,      -- Dark gray for borders
      background_color = 21,
      visited_color = 6,     -- Light gray for visited rooms
      current_color = 7,     -- White for current room
      unexplored_color = 1,  -- Dark blue for unexplored but discovered (adjacent to visited)
      icon_size = 10,        -- Special room icon sprite size
      overlap_margin_x = 32, -- Check x buffer (16 margin + 16 buffer)
      overlap_margin_y = 16, -- Check y margin
      tween_duration = 15,   -- Frames to tween between positions
      icons = {              -- Special room sprites (10x10)
         start = 192,
         shop = 193,
         treasure = 194,
         boss = 195,
      },
   },
   title = "Pizak",
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
   attack = GameConstants.buttons.o,
   place_bomb = GameConstants.buttons.x,
   aim_up = GameConstants.buttons.up,
   aim_down = GameConstants.buttons.down,
   aim_left = GameConstants.buttons.left,
   aim_right = GameConstants.buttons.right,
   move_up = GameConstants.buttons.up2,
   move_down = GameConstants.buttons.down2,
   move_left = GameConstants.buttons.left2,
   move_right = GameConstants.buttons.right2,
}

-- Collision layers (bitmasking for fast collision filtering)
GameConstants.CollisionLayers = {
   PLAYER = 1,            -- 0b000001
   ENEMY = 2,             -- 0b000010
   PLAYER_PROJECTILE = 4, -- 0b000100
   ENEMY_PROJECTILE = 8,  -- 0b001000
   PICKUP = 16,           -- 0b010000
   WORLD = 32,            -- 0b100000
   OBSTACLE = 64,         -- 0b1000000
   EXPLOSION = 128,       -- 0b10000000 (hits Player + Enemy + Obstacle)
}

-- What each layer can collide with (bitmask)
GameConstants.CollisionMasks = {
   [1] = 2 + 8 + 16 + 32 + 64 + 128, -- PLAYER: Enemy + EnemyProjectile + Pickup + World + Obstacle + Explosion
   [2] = 1 + 4 + 32 + 64 + 128,      -- ENEMY: Player + PlayerProjectile + World + Obstacle + Explosion
   [4] = 2 + 32 + 64,                -- PLAYER_PROJECTILE: Enemy + World + Obstacle
   [8] = 1 + 32 + 64,                -- ENEMY_PROJECTILE: Player + World + Obstacle
   [16] = 1 + 16,                    -- PICKUP: Player + other Pickups
   [32] = 1 + 2 + 4 + 8,             -- WORLD: Everything except Pickup
   [64] = 1 + 2 + 4 + 8 + 128,       -- OBSTACLE: Player + Enemy + Projectiles + Explosion
   [128] = 1 + 2 + 64,               -- EXPLOSION: Player + Enemy + Obstacle
}

-- Entity type to collision layer mapping
GameConstants.EntityCollisionLayer = {
   Player = GameConstants.CollisionLayers.PLAYER,
   Enemy = GameConstants.CollisionLayers.ENEMY,
   Projectile = GameConstants.CollisionLayers.PLAYER_PROJECTILE,
   MeleeHitbox = GameConstants.CollisionLayers.PLAYER_PROJECTILE,
   EnemyProjectile = GameConstants.CollisionLayers.ENEMY_PROJECTILE,
   ProjectilePickup = GameConstants.CollisionLayers.PICKUP,
   HealthPickup = GameConstants.CollisionLayers.PICKUP,
   Coin = GameConstants.CollisionLayers.PICKUP,
   Key = GameConstants.CollisionLayers.PICKUP,
   Bomb = GameConstants.CollisionLayers.PICKUP,
   Rock = GameConstants.CollisionLayers.OBSTACLE,
   Destructible = GameConstants.CollisionLayers.OBSTACLE,
   Explosion = GameConstants.CollisionLayers.EXPLOSION, -- Explosions hit Player + Enemy + Obstacle
}

return GameConstants
