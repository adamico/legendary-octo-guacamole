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

-- Draw spotlight circle for an entity
-- @param entity - Entity with spotlight tag
-- @param clip_square - Clipping rectangle {x, y, w, h}
local function draw_spotlight_entity(entity, clip_square)
   local center_x = entity.x + (entity.width or 16) / 2
   local center_y = entity.y + (entity.height or 16) / 2
   local radius = entity.spotlight_radius or 48

   clip(clip_square.x, clip_square.y, clip_square.w, clip_square.h)
   circfill(center_x, center_y, radius, LIGHTING_SPOTLIGHT_COLOR)
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
