-- Palette utility for extended color initialization
local Palette = {}

Palette.BASE_COLORS = {
   [0] = 0x000000,
   [1] = 0x1d2b53,
   [2] = 0x7e2553,
   [3] = 0x008751,
   [4] = 0xab5236,
   [5] = 0x5f574f,
   [6] = 0xc2c3c7,
   [7] = 0xfff1e8,
   [8] = 0xff004d,
   [9] = 0xffa300,
   [10] = 0xffec27,
   [11] = 0x00e436,
   [12] = 0x29adff,
   [13] = 0x83769c,
   [14] = 0xff77a8,
   [15] = 0xffccaa
}

-- Initialize extended palette with lighter/darker color variants
-- Colors 32-47: Lighter variants of 0-15
-- Colors 48-63: Darker variants of 0-15
function Palette.init_extended_palette()
   for i = 0, 15 do
      local c = Palette.BASE_COLORS[i]
      local r = (c >> 16) & 0xff
      local g = (c >> 8) & 0xff
      local b = c & 0xff

      -- Lighter variant (2% toward white)
      local lr = flr(r + (255 - r) * 0.02)
      local lg = flr(g + (255 - g) * 0.02)
      local lb = flr(b + (255 - b) * 0.02)
      local light_argb = 0xff000000 | (lr << 16) | (lg << 8) | lb
      pal(32 + i, light_argb, 2)

      -- Darker variant (50% toward black)
      local dr = flr(r * 0.5)
      local dg = flr(g * 0.5)
      local db = flr(b * 0.5)
      local dark_argb = 0xff000000 | (dr << 16) | (dg << 8) | db
      pal(48 + i, dark_argb, 2)
   end
end

return Palette
