-- Lighting system: palette initialization and spotlight effects

local Lighting = {}

Lighting.SPOTLIGHT_COLOR = 33
Lighting.SHADOW_COLOR = 32

local spotlight_initialized = false

-- Initialize extended palette with lighter/darker color variants
function Lighting.init_extended_palette()
   local base_colors = {
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

   for i = 0, 15 do
      local c = base_colors[i]
      local r = (c >> 16) & 0xff
      local g = (c >> 8) & 0xff
      local b = c & 0xff

      -- Lighter variant (50% toward white)
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

-- Initialize spotlight color table
function Lighting.init_spotlight()
   if spotlight_initialized then return end
   Lighting.reset_spotlight()
   spotlight_initialized = true
end

-- Reset spotlight color mappings
function Lighting.reset_spotlight()
   local spotlight_row_address = 0x8000 + Lighting.SPOTLIGHT_COLOR * 64
   local shadow_row_address = 0x8000 + Lighting.SHADOW_COLOR * 64

   for target_col = 0, 63 do
      local bright_col, dark_col

      bright_col = target_col
      dark_col = target_col

      if target_col <= 15 then
         bright_col = 32 + target_col
         dark_col = 48 + target_col
      elseif target_col >= 32 and target_col <= 47 then
         local base = target_col - 32
         dark_col = 48 + base
      elseif target_col >= 48 and target_col <= 63 then
         local base = target_col - 48
         bright_col = base
      end

      poke(spotlight_row_address + target_col, bright_col)
      poke(shadow_row_address + target_col, dark_col)
   end

   poke(0x550b, 0x3f)
end

-- Draw spotlight circle for an entity
-- @param entity - Entity with spotlight tag
-- @param clip_square - Clipping rectangle {x, y, w, h}
local function draw_spotlight_entity(entity, clip_square)
   local center_x = entity.x + (entity.width or 16) / 2
   local center_y = entity.y + (entity.height or 16) / 2
   local radius = entity.spotlight_radius or 48

   clip(clip_square.x, clip_square.y, clip_square.w, clip_square.h)
   circfill(center_x, center_y, radius, Lighting.SPOTLIGHT_COLOR)
   clip()
end

-- Update lighting for all spotlight entities
-- @param world - ECS world
-- @param clip_square - Clipping rectangle
function Lighting.update(world, clip_square)
   Lighting.reset_spotlight()
   world.sys("spotlight", function(entity)
      draw_spotlight_entity(entity, clip_square)
   end)()
end

return Lighting
