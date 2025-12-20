SCREEN_WIDTH = 480
SCREEN_HEIGHT = 270
GRID_SIZE = 16
SOLID_FLAG = 0

local GameConstants = {
   Player = {
      invulnerable_time = 120, -- frames
      move_speed = vec(1, 1),
      sprite_index_offsets = {
         down = 238,
         right = 246,
         left = 246,
         up = 253,
      },
      width = 24,
      height = 32,
      max_health = 100,
      shot_cost = 20,
      recovery_percent = 0.8,
      regen_rate = 5,    -- HP per second (0 = disabled)
      regen_delay = 3.0, -- Seconds without shooting before regen starts
   },
   Projectile = {
      damage = 10, -- HP damage per projectile hit
      sprite_index_offsets = {
         down = 78,
         right = 77,
         up = 78,
         left = 77,
      },
   },
   ProjectilePickup = {
      sprite_index_offsets = {
         down = 78,
         right = 77,
         up = 78,
         left = 77,
      },
   },
   Enemy = {
      Skulker = {
         hp = 20,
         speed = 0.5,
         contact_damage = 10,
         sprite_index_offsets = {
            down = 254,
            right = 255,
            up = 256,
         },
         width = 16,
         height = 16,
      },
      drop_chance = 1.0, -- 100% drop rate for MVP testing
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
