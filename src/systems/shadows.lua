-- Shadows system: shadow entity sync and drawing

local HitboxUtils = require("src/utils/hitbox_utils")
local Rendering = require("src/systems/rendering")

local Shadows = {}

-- Sync shadow entity properties to parent
local function sync_shadow(world, shadow)
   local parent = shadow.parent

   if not parent or not world.msk(parent) then
      world.del(shadow)
      return
   end

   -- Optimization: skip syncing properties for static parent objects
   if parent.static then return end

   shadow.x = parent.x
   shadow.y = parent.y
   shadow.w = parent.width or 16
   shadow.h = parent.height or 16
   shadow.shadow_offset_y = parent.shadow_offset_y or 0
   shadow.shadow_offsets_y = parent.shadow_offsets_y
   shadow.shadow_offset_x = parent.shadow_offset_x or 0
   shadow.shadow_offsets_x = parent.shadow_offsets_x
   shadow.shadow_width = parent.shadow_width
   shadow.shadow_height = parent.shadow_height
   shadow.shadow_widths = parent.shadow_widths
   shadow.shadow_heights = parent.shadow_heights
   shadow.direction = parent.direction or parent.current_direction

   -- Propagate room_key for visibility filtering
   shadow.room_key = parent.room_key
end

-- Draw a shadow entity
-- @param world - ECS world
-- @param shadow - Shadow entity
-- @param clip_square - Clipping rectangle {x, y, w, h}
local function draw_shadow(world, shadow, clip_square)
   local parent = shadow.parent
   if not parent or not world.msk(parent) then return end

   local dir = parent.direction or parent.current_direction
   local hb = HitboxUtils.get_hitbox(parent)

   local sw = shadow.shadow_width
   if shadow.shadow_widths and dir and shadow.shadow_widths[dir] then
      sw = shadow.shadow_widths[dir]
   end
   if not sw then
      local w_scale = 0.8
      if hb.w < 8 then w_scale = 1.0 end
      sw = hb.w * w_scale
   end

   local sh = shadow.shadow_height
   if shadow.shadow_heights and dir and shadow.shadow_heights[dir] then
      sh = shadow.shadow_heights[dir]
   end
   sh = sh or 3

   local offset_y = shadow.shadow_offset_y or 0
   if shadow.shadow_offsets_y and dir and shadow.shadow_offsets_y[dir] then
      offset_y = shadow.shadow_offsets_y[dir]
   end

   local offset_x = shadow.shadow_offset_x or 0
   if shadow.shadow_offsets_x and dir and shadow.shadow_offsets_x[dir] then
      offset_x = shadow.shadow_offsets_x[dir]
   end

   local cx = flr(hb.x + hb.w / 2) + offset_x
   local ground_y = flr((hb.y + hb.h) + (parent.z or 0) - (parent.sprite_offset_y or 0))
   local cy = ground_y + offset_y

   local x1 = cx - flr(sw / 2)
   local x2 = cx + flr(sw / 2)
   local y1 = cy - flr(sh / 2)
   local y2 = cy + flr(sh / 2)

   clip(clip_square.x, clip_square.y, clip_square.w, clip_square.h)
   palt(0, false)
   ovalfill(x1, y1, x2, y2, 0)
   palt(0, true)
   clip()
end

-- Sync all shadow entities to their parents
-- @param world - ECS world
function Shadows.sync(world)
   world.sys("shadow_sync", function(e) sync_shadow(world, e) end)()
end

-- Draw all shadow entities
-- @param world - ECS world
-- @param clip_square - Clipping rectangle
function Shadows.draw(world, clip_square)
   world.sys("background,drawable_shadow", function(shadow)
      -- Filter by room_key (same logic as Rendering)
      if shadow.room_key and not Rendering.active_room_keys[shadow.room_key] then
         return
      end
      draw_shadow(world, shadow, clip_square)
   end)()
end

return Shadows
