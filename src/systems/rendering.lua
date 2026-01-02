-- Rendering system: core entity drawing (Picobloc ECS)
local qsort = require("lib/qsort")
local Rotator = require("src/systems/sprite_rotator")

local Rendering = {}

-- Outline offsets for 8-neighbor technique
local OUTLINE_OFFSETS = {
   {-1, 0}, {1, 0}, {0, -1}, {0, 1},
   {-1, -1}, {1, -1}, {-1, 1}, {1, 1}
}

-- Draw a sprite with a colored outline
local function draw_outlined(sprite_index, x, y, outline_color, flip_x, flip_y)
   outline_color = outline_color or 0
   for i = 1, 63 do pal(i, outline_color, 0) end
   for _, o in ipairs(OUTLINE_OFFSETS) do
      spr(sprite_index, x + o[1], y + o[2], flip_x, flip_y)
   end
   pal()
   spr(sprite_index, x, y, flip_x, flip_y)
end

-- Draw a composite sprite
local function draw_outlined_composite(sprite_top, sprite_bottom, x, y, width, height, split_row, outline_color, flip_x,
                                       flip_y)
   outline_color = outline_color or 0
   split_row = split_row or flr(height / 2)
   local bottom_height = height - split_row

   local function draw_composite(ox, oy)
      sspr(sprite_top, 0, 0, width, split_row, x + ox, y + oy, width, split_row, flip_x, flip_y)
      sspr(sprite_bottom, 0, split_row, width, bottom_height, x + ox, y + oy + split_row, width, bottom_height, flip_x,
         flip_y)
   end

   for i = 1, 63 do pal(i, outline_color, 0) end
   for _, o in ipairs(OUTLINE_OFFSETS) do
      draw_composite(o[1], o[2])
   end
   pal()
   draw_composite(0, 0)
end

-- Procedural death effect
local function apply_death_effect(x, y, width, height, sprite_index, flip_x, flip_y, timer)
   local max_t = 30
   local p = min(timer / max_t, 1.0)

   -- Shake
   local sx = x + rnd(2) - 1
   local sy = y + rnd(2) - 1

   -- Flash/Flicker
   if timer < 4 then
      for i = 1, 63 do pal(i, 7) end
   else
      if flr(timer / 4) % 2 == 0 then
         pal(6, 8); pal(5, 2); pal(13, 2)
      end
   end

   -- Stretch
   local target_h = height * (1 - p)
   local target_w = width * (1 + p * 1.5)
   local draw_x = sx - (target_w - width) / 2
   local draw_y = sy + (height - target_h)

   sspr(sprite_index, 0, 0, width, height, draw_x, draw_y, target_w, target_h, flip_x, flip_y)
   pal()
end

-- Helper to draw a single entity from buffers
function Rendering.draw_one(i, pos, drawable, size, flash, animatable, enemy_ai, minion_ai)
   -- Flash Logic
   local is_flashing = false
   if flash then
      local ft = flash.flash_timer[i]
      if ft > 0 then
         flash.flash_timer[i] = ft - 1
         if flr(ft / 4) % 2 == 0 then
            for c = 1, 15 do pal(c, 7) end
            is_flashing = true
         end
      end
   end

   local x = pos.x[i]
   local y = pos.y[i] - (pos.z[i] or 0)
   local sx = x + (drawable.sprite_offset_x and drawable.sprite_offset_x[i] or 0)
   local sy = y + (drawable.sprite_offset_y and drawable.sprite_offset_y[i] or 0)

   local flip_x = drawable.flip_x[i]
   local flip_y = drawable.flip_y[i]
   local outline = drawable.outline_color[i]
   local w = size and size.width[i] or 16
   local h = size and size.height[i] or 16

   -- procedural death?
   local fsm = (enemy_ai and enemy_ai.fsm[i]) or (minion_ai and minion_ai.fsm[i])
   if fsm and fsm:is("death") and animatable then
      local sprite = drawable.sprite_index[i] or (drawable.sprite_top and drawable.sprite_top[i]) or 0
      apply_death_effect(sx, sy, w, h, sprite, flip_x, flip_y, animatable.anim_timer[i])
      return
   end

   local s_top = drawable.sprite_top and drawable.sprite_top[i]
   local s_bot = drawable.sprite_bottom and drawable.sprite_bottom[i]

   if s_top and s_bot and s_top > 0 then
      local split = drawable.split_row and drawable.split_row[i]
      draw_outlined_composite(s_top, s_bot, sx, sy, w, h, split, outline, flip_x, flip_y)
   else
      -- Normal Draw with Rotation Support
      local sprite = drawable.sprite_index[i]
      local rotation = drawable.rotation and drawable.rotation[i] or 0

      -- Apply rotation if needed (returns Userdata or original sprite index)
      if rotation ~= 0 then
         sprite = Rotator.get(sprite, rotation)
      end

      if outline then
         draw_outlined(sprite, sx, sy, outline, flip_x, flip_y)
      else
         spr(sprite, sx, sy, flip_x, flip_y)
      end
   end

   if is_flashing then pal() end
end

-- Check if entity's room_key matches allowed keys
local function is_visible(room_key_buffer, i, allowed_keys)
   if not room_key_buffer then return true end -- No component = always visible
   local rk = room_key_buffer.value[i]
   if not rk then return true end              -- No value = always visible

   -- allowed_keys should be a set: { ["0,0"] = true, ["1,0"] = true }
   return allowed_keys[rk] == true
end

-- New draw_layer using Picobloc queries
-- @param world: ECS world
-- @param tag_filter: string or table of tags to filter by (or generic components)
-- @param sorted: boolean, if true sorts by Y
-- @param visible_rooms: (optional) table of room keys { ["0,0"]=true, ... }
function Rendering.draw_layer(world, tag_filter, sorted, visible_rooms)
   -- Construct query components
   -- We always need position and drawable. We optionally take size, flash, etc.
   local components = {"position", "drawable", "size?", "flash?", "room_key?", "animatable?", "enemy_ai?", "minion_ai?"}

   -- Add tag filters (split comma-separated strings)
   if tag_filter then
      if type(tag_filter) == "string" then
         for _, tag in ipairs(split(tag_filter, ",")) do
            table.insert(components, tag)
         end
      else
         for _, t in ipairs(tag_filter) do
            table.insert(components, t)
         end
      end
   end

   local render_list = {}

   world:query(components, function(ids, pos, drawable, size, flash, room_key, animatable, enemy_ai, minion_ai)
      for i = ids.first, ids.last do
         -- Room Visibility Check
         if not visible_rooms or is_visible(room_key, i, visible_rooms) then
            if sorted then
               local obj = {
                  i = i,
                  y = pos.y[i],
                  z = pos.z[i] or 0,
                  sort_offset = drawable.sort_offset_y[i] or (size and size.height[i]) or 16,
                  -- Capture buffers for deferred rendering
                  pos = pos,
                  drawable = drawable,
                  size = size,
                  flash = flash,
                  animatable = animatable,
                  enemy_ai = enemy_ai,
                  minion_ai = minion_ai
               }
               add(render_list, obj)
            else
               -- Immediate draw
               Rendering.draw_one(i, pos, drawable, size, flash, animatable, enemy_ai, minion_ai)
            end
         end
      end
   end)

   if sorted then
      qsort(render_list, function(a, b)
         -- Y-Sort: Feet position
         local ay = a.y + a.sort_offset
         local by = b.y + b.sort_offset
         return ay < by
      end)

      for _, obj in ipairs(render_list) do
         Rendering.draw_one(obj.i, obj.pos, obj.drawable, obj.size, obj.flash, obj.animatable, obj.enemy_ai,
            obj.minion_ai)
      end
   end
end

-- Export utility for HUD/UI drawing
Rendering.draw_outlined = draw_outlined

return Rendering
