-- Floating Text System: displays damage/heal numbers above entities
local GameConstants = require("src/game/game_config")
local TextUtils = require("src/utils/text_utils")

local FloatingText = {}

-- Active floating text entries
local active_texts = {}

-- Configuration defaults
-- See src/game/config/effects.lua for the actual configuration.
local function get_config()
   return GameConstants.FloatingText
end

--- Spawn a floating text at an entity's position
---
--- @param x, y: world position (center of entity recommended)
--- @param amount: number or string to display
--- @param text_type: "damage", "heal", or "pickup" (optional, auto-detected from amount if omitted)
--- @param sprite_index: optional sprite index to display before the text
function FloatingText.spawn(x, y, amount, text_type, sprite_index)
   local config = get_config()

   -- Determine type from amount if not specified
   if not text_type then
      text_type = (type(amount) == "number" and amount < 0) and "damage" or "heal"
   end

   -- Determine color based on type
   local color = config[text_type.."_color"] or (text_type == "damage" and config.damage_color) or config.heal_color

   -- Format amount
   local text
   if type(amount) == "number" then
      local display_amount = flr(abs(amount))
      -- For pickups with sprites, show "+n" format
      if sprite_index then
         text = "+"..tostring(display_amount)
      else
         text = tostring(display_amount)
      end
   else
      text = tostring(amount)
   end

   -- Add slight random horizontal offset to prevent overlap
   local offset_x = (rnd(1) - 0.5) * config.spread

   -- Check for nearby active texts and stagger Y position to prevent overlap
   local base_y = y + config.offset_y
   local stagger_y = 0
   local stagger_amount = 10 -- Vertical spacing between stacked texts

   for _, existing in ipairs(active_texts) do
      -- Check if existing text is at similar position (within spread range)
      if abs(existing.x - (x + offset_x)) < 16 and abs(existing.y - base_y - stagger_y) < stagger_amount then
         stagger_y = stagger_y - stagger_amount
      end
   end

   local entry = {
      x = x + offset_x,
      y = base_y + stagger_y,
      text = text,
      color = color,
      timer = config.duration,
      rise_speed = config.rise_speed,
      outline_color = config.outline_color,
      fade_start = config.duration - config.fade_duration,
      sprite_index = sprite_index, -- optional sprite to draw
   }

   table.insert(active_texts, entry)
end

-- Convenience function to spawn damage text at an entity
function FloatingText.spawn_at_entity(entity, amount, text_type, sprite_index)
   local cx = entity.x + (entity.width or 16) / 2
   local cy = entity.y
   FloatingText.spawn(cx, cy, amount, text_type, sprite_index)
end

-- Update all active floating texts (call once per frame)
function FloatingText.update()
   local i = 1
   while i <= #active_texts do
      local entry = active_texts[i]
      entry.timer -= 1
      entry.y -= entry.rise_speed

      if entry.timer <= 0 then
         table.remove(active_texts, i)
      else
         i += 1
      end
   end
end

-- Draw all active floating texts (call during draw phase)
function FloatingText.draw()
   local config = get_config()

   for _, entry in ipairs(active_texts) do
      -- Calculate alpha based on remaining time (for fade effect)
      local alpha = 1
      if entry.timer < entry.fade_start then
         -- In fade phase
         alpha = entry.timer / entry.fade_start
      end

      -- Center the text horizontally
      local text_width = #entry.text * 4    -- Approximate character width
      local draw_x = entry.x - text_width / 2
      local draw_y = entry.y

      -- Draw with fade effect (Picotron supports fillp patterns for transparency)
      -- For simplicity, use color blinking during fade

      if alpha < 0.5 and (t() * 30) % 2 < 1 then
         -- Skip drawing every other frame during fade for blink effect
      else
         -- If we have a sprite, draw it first (8x8 scaled to fit)
         local sprite_width = 0
         if entry.sprite_index then
            sprite_width = config.icon_size + 2    -- sprite + small gap

            local ix = draw_x + (config.icon_offset_x or -4)
            local iy = draw_y + (config.icon_offset_y or -1)
            local isize = config.icon_size or 8

            -- Use sspr to scale 16x16 sprite down to target size
            -- sspr(s, sx, sy, sw, sh, dx, dy, dw, dh)
            sspr(entry.sprite_index, 0, 0, 16, 16, ix, iy, isize, isize)
         end

         TextUtils.print_outlined(entry.text, draw_x + sprite_width - 4, draw_y, entry.color, entry.outline_color)
      end
   end
end

-- Clear all active floating texts (e.g., on room transition)
function FloatingText.clear()
   active_texts = {}
end

-- Get count of active texts (for debugging)
function FloatingText.count()
   return #active_texts
end

return FloatingText
