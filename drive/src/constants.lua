SCREEN_WIDTH = 480
SCREEN_HEIGHT = 270
UI_HEIGHT = 48
GRID_SIZE = 16
STARTING_SEEDS = 10

Game = {
   Player = {
      invulnerable_time = 120, -- frames
      max_health = 4,
      move_speed = vec(1, 1),
      sprite_index_offset = 8,
      width = 24,
      height = 32,
   },
   title = "Necrotron",
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

Game.controls = {
   move_up = Game.buttons.up,
   move_down = Game.buttons.down,
   move_left = Game.buttons.left,
   move_right = Game.buttons.right,
   spawn_tree = Game.buttons.o,
}

Keys = {
   show_attributes = "f2",
   show_hitboxes = "f3",
   godmode = "f4",
   noclip = "f5",
   debug = "f6",
}