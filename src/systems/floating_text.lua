-- Floating Text System: displays damage/heal numbers above entities
local GameConstants = require("src/game/game_config")

local FloatingText = {}

-- Active floating text entries
local active_texts = {}

-- Configuration defaults (can be overridden via GameConstants.FloatingText)
local function get_config()
   return GameConstants.FloatingText or {
      rise_speed = 0.5,   -- Pixels per frame to rise
      duration = 45,      -- Frames before fade out
      fade_duration = 15, -- Frames for fade out (part of total duration)
      damage_color = 8,   -- Red for damage
      heal_color = 11,    -- Green for healing
      outline_color = 0,  -- Black outline
      offset_y = -8,      -- Initial vertical offset from entity top
      spread = 8,         -- Horizontal spread for multiple texts
   }
end

-- Spawn a floating text at an entity's position
-- @param x, y: world position (center of entity recommended)
-- @param amount: number to display (positive for heal, negative for damage)
-- @param text_type: "damage" or "heal" (optional, auto-detected from amount if omitted)
function FloatingText.spawn(x, y, amount, text_type)
   local config = get_config()

   -- Determine type from amount if not specified
   if not text_type then
      text_type = amount < 0 and "damage" or "heal"
   end

   -- Determine color based on type
   local color = config[text_type.."_color"] or (text_type == "damage" and config.damage_color) or config.heal_color

   -- Format amount (always show absolute value as integer, type determines color)
   local display_amount = flr(abs(amount))
   local text = tostring(display_amount)

   -- Add slight random horizontal offset to prevent overlap
   local offset_x = (rnd(1) - 0.5) * config.spread

   local entry = {
      x = x + offset_x,
      y = y + config.offset_y,
      text = text,
      color = color,
      timer = config.duration,
      rise_speed = config.rise_speed,
      outline_color = config.outline_color,
      fade_start = config.duration - config.fade_duration,
   }

   table.insert(active_texts, entry)
end

-- Convenience function to spawn damage text at an entity
function FloatingText.spawn_at_entity(entity, amount, text_type)
   local cx = entity.x + (entity.width or 16) / 2
   local cy = entity.y
   FloatingText.spawn(cx, cy, amount, text_type)
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
   for _, entry in ipairs(active_texts) do
      -- Calculate alpha based on remaining time (for fade effect)
      local alpha = 1
      if entry.timer < entry.fade_start then
         -- In fade phase
         alpha = entry.timer / entry.fade_start
      end

      -- Center the text horizontally
      local text_width = #entry.text * 4 -- Approximate character width
      local draw_x = entry.x - text_width / 2
      local draw_y = entry.y

      -- Draw with fade effect (Picotron supports fillp patterns for transparency)
      -- For simplicity, use color blinking during fade

      if alpha < 0.5 and (t() * 30) % 2 < 1 then
         -- Skip drawing every other frame during fade for blink effect
      else
         local TextUtils = require("src/utils/text_utils")
         TextUtils.print_outlined(entry.text, draw_x, draw_y, entry.color, entry.outline_color)
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
