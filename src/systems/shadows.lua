-- Shadows system: draw shadows for entities with position + shadow components

local Shadows = {}
local EntityUtils = require("src/utils/entity_utils")

--- Draw shadows for all entities with position + shadow + size components
--- @param world ECSWorld - picobloc World
function Shadows.draw(world)
   -- Query entities with all required components
   -- size is needed for hitbox-based shadow positioning
   world:query({"position", "shadow", "size", "direction?"}, function(ids, pos, shadow, size, dir)
      for i = ids.first, ids.last do
         -- Get direction string for per-direction lookups
         local dir_name = nil
         if dir then
            dir_name = EntityUtils.get_direction_name(dir.dir_x[i], dir.dir_y[i])
         end

         -- Calculate shadow width (from config or derived from entity size)
         local sw = shadow.shadow_width[i]
         local shadow_widths = shadow.shadow_widths[i]
         if shadow_widths and dir_name and shadow_widths[dir_name] then
            sw = shadow_widths[dir_name]
         end
         if not sw or sw == 0 then
            local w = size.width[i] or 16
            local w_scale = (w < 8) and 1.0 or 0.8
            sw = w * w_scale
         end

         -- Get shadow height
         local sh = shadow.shadow_height[i]
         local shadow_heights = shadow.shadow_heights[i]
         if shadow_heights and dir_name and shadow_heights[dir_name] then
            sh = shadow_heights[dir_name]
         end
         sh = sh or 3

         -- Get Y offset
         local offset_y = shadow.shadow_offset_y[i] or 0
         local shadow_offsets_y = shadow.shadow_offsets_y[i]
         if shadow_offsets_y and dir_name and shadow_offsets_y[dir_name] then
            offset_y = shadow_offsets_y[dir_name]
         end

         -- Get X offset
         local offset_x = shadow.shadow_offset_x[i] or 0
         local shadow_offsets_x = shadow.shadow_offsets_x[i]
         if shadow_offsets_x and dir_name and shadow_offsets_x[dir_name] then
            offset_x = shadow_offsets_x[dir_name]
         end

         -- Calculate shadow center position
         local x = pos.x[i]
         local y = pos.y[i]
         local w = size.width[i] or 16
         local h = size.height[i] or 16

         local cx = flr(x + w / 2) + offset_x
         local cy = flr(y + h) + offset_y

         -- Calculate shadow oval bounds
         local x1 = cx - flr(sw / 2)
         local x2 = cx + flr(sw / 2)
         local y1 = cy - flr(sh / 2)
         local y2 = cy + flr(sh / 2)

         -- Draw shadow
         palt(0, false)
         ovalfill(x1, y1, x2, y2, 0)
         palt(0, true)
      end
   end)
end

return Shadows
