-- Rendering system: core entity drawing
-- Focused on sprite drawing, layer rendering, and palette swaps

local qsort = require("lib/qsort")
local Effects = require("src/systems/effects")
local Rotator = require("src/systems/sprite_rotator")

local Rendering = {}

-- Outline offsets for 8-neighbor technique
local OUTLINE_OFFSETS = {
   {-1, 0}, {1, 0}, {0, -1}, {0, 1},
   {-1, -1}, {1, -1}, {-1, 1}, {1, 1}
}

-- Draw a sprite with a colored outline
-- @param sprite_index - Sprite to draw
-- @param x, y - Position
-- @param outline_color - Color for outline (default: 0 black)
-- @param flip_x, flip_y - Optional flip flags
function Rendering.draw_outlined(sprite_index, x, y, outline_color, flip_x, flip_y)
   outline_color = outline_color or 0

   -- Set all colors to outline color
   for i = 1, 63 do pal(i, outline_color, 0) end

   -- Draw 8 outline sprites at offset positions
   for _, o in ipairs(OUTLINE_OFFSETS) do
      spr(sprite_index, x + o[1], y + o[2], flip_x, flip_y)
   end

   -- Reset palette and draw center sprite
   pal()
   spr(sprite_index, x, y, flip_x, flip_y)
end

-- Draw a composite sprite (top + bottom halves) with a colored outline
function Rendering.draw_outlined_composite(sprite_top, sprite_bottom, x, y, width, height, split_row, outline_color,
                                           flip_x, flip_y)
   outline_color = outline_color or 0
   split_row = split_row or flr(height / 2)
   local bottom_height = height - split_row

   -- Helper to draw the composite sprite
   local function draw_composite(ox, oy)
      -- Draw top half
      sspr(sprite_top, 0, 0, width, split_row, x + ox, y + oy, width, split_row, flip_x, flip_y)
      -- Draw bottom half
      sspr(sprite_bottom, 0, split_row, width, bottom_height, x + ox, y + oy + split_row, width, bottom_height, flip_x,
         flip_y)
   end

   -- Set all colors to outline color (keep color 0 transparent)
   for i = 1, 63 do pal(i, outline_color, 0) end

   -- Draw 8 outline offsets
   for _, o in ipairs(OUTLINE_OFFSETS) do
      draw_composite(o[1], o[2])
   end

   pal()

   -- Draw center composite normally
   draw_composite(0, 0)
end

-- Apply palette swaps for an entity
local function apply_palette_swaps(entity)
   if not entity.palette_swaps then return end
   for _, swap in ipairs(entity.palette_swaps) do
      pal(swap.from, swap.to)
   end
end

-- Internal sprite drawer (combines flash check and standard drawing)
local function draw_sprite(entity)
   local was_flashing = entity.flash_timer and entity.flash_timer > 0
   Effects.update_flash(entity)

   -- Actual drawing
   local flip_x = entity.flip_x or entity.flip or false
   local flip_y = entity.flip_y or false
   local sx = entity.x + (entity.sprite_offset_x or 0)
   local sy = entity.y + (entity.sprite_offset_y or 0) - (entity.z or 0)

   -- Apply palette swaps
   local palette_swapped = false
   if entity.palette_swaps then
      apply_palette_swaps(entity)
      palette_swapped = true
   end

   -- Check for death state to apply procedural effects
   if entity.fsm and entity.fsm:is("death") then
      local t = entity.anim_timer or 0
      local max_t = 30
      local p = min(t / max_t, 1.0)
      sx = sx + rnd(2) - 1
      sy = sy + rnd(2) - 1
      if t < 4 then
         for i = 1, 15 do pal(i, 7) end
         for i = 32, 63 do pal(i, 7) end
      else
         if flr(t / 4) % 2 == 0 then
            pal(6, 8)
            pal(5, 2)
            pal(13, 2)
         end
      end
      local n = entity.sprite_index or 0
      local w = entity.width
      local h = entity.height
      local target_h = h * (1 - p)
      local target_w = w * (1 + p * 1.5)
      local draw_x = sx - (target_w - w) / 2
      local draw_y = sy + (h - target_h)
      sspr(n, 0, 0, w, h, draw_x, draw_y, target_w, target_h, flip_x, flip_y)
      pal()
      return
   end

   -- Check for composite sprite (top + bottom halves)
   if entity.sprite_top ~= nil and entity.sprite_bottom ~= nil then
      local width = entity.width
      local height = entity.height
      local split_row = entity.split_row

      -- Skip outline if entity is flashing (flash takes priority)
      if entity.outline_color ~= nil and not was_flashing then
         Rendering.draw_outlined_composite(
            entity.sprite_top, entity.sprite_bottom,
            sx, sy, width, height, split_row,
            entity.outline_color, flip_x, flip_y
         )
      else
         local bottom_height = height - split_row
         sspr(entity.sprite_top, 0, 0, width, split_row, sx, sy, width, split_row, flip_x, flip_y)
         sspr(entity.sprite_bottom, 0, split_row, width, bottom_height, sx, sy + split_row, width, bottom_height,
            flip_x, flip_y)
      end
   else
      -- Standard single sprite
      local drawable = entity.sprite_index
      if entity.rotation_angle and entity.rotation_angle ~= 0 then
         drawable = Rotator.get(entity.sprite_index, entity.rotation_angle)
      end

      -- Skip outline if entity is flashing (flash takes priority)
      if entity.outline_color ~= nil and not was_flashing then
         Rendering.draw_outlined(drawable, sx, sy, entity.outline_color, flip_x, flip_y)
      else
         spr(drawable, sx, sy, flip_x, flip_y)
      end
   end

   -- Reset palette if swapped OR if outlined (which calls pal()) OR was flashing
   if palette_swapped or (entity.outline_color ~= nil) or was_flashing then
      pal()
   end
end

-- Active room keys for visibility filtering (set by play.lua before drawing)
-- Entities with room_key will only be drawn if their key is in this table
Rendering.active_room_keys = {}

--- Set which rooms are currently visible (call before draw_layer)
--- @param room_keys Table of room key strings like {"0,0", "1,0"}
function Rendering.set_active_rooms(room_keys)
   Rendering.active_room_keys = {}
   for _, key in ipairs(room_keys) do
      Rendering.active_room_keys[key] = true
   end
end

--- Check if entity should be visible based on room_key
---
--- @param entity Entity to check
--- @return true if entity should be rendered
local function is_entity_visible(entity)
   -- Entities without room_key are always visible (player, projectiles, etc)
   if not entity.room_key then return true end

   -- Check if entity's room is in active rooms
   return Rendering.active_room_keys[entity.room_key] == true
end

--- Draws all entities matching 'tags'. Optionally sorts them by Y position.
---
--- Filters out entities whose room_key is not in active_room_keys
---
--- @param world ECS world
--- @param tags Table of tag strings like {"player", "enemy"}
--- @param sorted Boolean whether to sort entities by Y position
function Rendering.draw_layer(world, tags, sorted)
   if sorted then
      local entities = {}
      world.sys(tags, function(e)
         if is_entity_visible(e) then
            add(entities, e)
         end
      end)()

      -- Sort by Y position (foot position for proper 2.5D sorting)
      -- Use sort_offset_y to specify where the entity's "feet" are (default: bottom of sprite)
      qsort(entities, function(a, b)
         local ay = a.y + (a.sort_offset_y or a.height or 16)
         local by = b.y + (b.sort_offset_y or b.height or 16)
         return ay < by
      end)

      for i = 1, #entities do
         draw_sprite(entities[i])
      end
   else
      world.sys(tags, function(e)
         if is_entity_visible(e) then
            draw_sprite(e)
         end
      end)()
   end
end

-- Apply palette swaps for all palette_swappable entities
function Rendering.apply_palette_swaps(world)
   world.sys("palette_swappable", apply_palette_swaps)()
end

return Rendering
