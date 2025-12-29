-- Controls and input configuration

local buttons = {
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

local controls = {
   attack = buttons.o,
   place_bomb = buttons.x,
   aim_up = buttons.up,
   aim_down = buttons.down,
   aim_left = buttons.left,
   aim_right = buttons.right,
   move_up = buttons.up2,
   move_down = buttons.down2,
   move_left = buttons.left2,
   move_right = buttons.right2,
}

return {
   buttons = buttons,
   controls = controls,
}
