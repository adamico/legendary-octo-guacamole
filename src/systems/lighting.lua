local Palette = require("src/utils/palette")

local Lighting = {}

local spotlight_initialized = false

-- Initialize extended palette via utility
function Lighting.init_extended_palette()
   Palette.init_extended_palette()
end

-- Initialize spotlight color table
function Lighting.init_spotlight()
   if spotlight_initialized then return end
   Lighting.reset_spotlight()
   spotlight_initialized = true
end

-- Reset spotlight color mappings
function Lighting.reset_spotlight()
   local spotlight_row_address = 0x8000 + LIGHTING_SPOTLIGHT_COLOR * 64
   local shadow_row_address = 0x8000 + LIGHTING_SHADOW_COLOR * 64

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

-- Update lighting for all spotlight entities
-- @param world - ECS world
-- @param clip_square - Clipping rectangle
function Lighting.update(world, clip_square)
   Lighting.reset_spotlight()

   clip(clip_square.x, clip_square.y, clip_square.w, clip_square.h)

   world:query({"position", "spotlight", "size?"}, function(ids, pos, spotlight, size)
      for i = ids.first, ids.last do
         local width = size and size.width[i] or 16
         local height = size and size.height[i] or 16

         local x = pos.x[i]
         local y = pos.y[i]
         -- Use center of entity
         local center_x = x + width / 2
         local center_y = y + height / 2

         local radius = spotlight.radius[i] or 48

         -- Check if color customization is needed (but implementation uses global palette row currently)
         -- So we stick to drawing with LIGHTING_SPOTLIGHT_COLOR

         circfill(center_x, center_y, radius, LIGHTING_SPOTLIGHT_COLOR)
      end
   end)

   clip()
end

return Lighting
