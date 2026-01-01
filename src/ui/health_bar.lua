local GameConstants = require("src/game/game_config")

local HealthBar = {}

-- Helper to apply palette swaps based on config
-- Heart sprite base colors (in luminance order): 7, 8, 24, 2
-- colors array maps: {target_for_7, target_for_8, target_for_24, target_for_2}
local function apply_palette(colors)
   if not colors then return end
   pal(7, colors[1], 0)
   pal(8, colors[2], 0)
   pal(24, colors[3], 0)
   pal(2, colors[4], 0)
end

-- Helper to draw a heart (full, half, or empty)
local function draw_heart_sprite(x, y, type, config, colors)
   apply_palette(colors)

   local sprite
   if type == "full" then
      sprite = config.heart_sprite
   elseif type == "half" then
      sprite = config.half_heart_sprite
   else
      -- Empty
      sprite = config.empty_heart_sprite or config.heart_sprite
   end

   spr(sprite, x, y, false, false, 2, 2)

   pal()
end

function HealthBar.draw(player)
   if not player or not player.hp then return end

   local config = GameConstants.Hud.health_bar
   local x = config.x
   local y = config.y
   local spacing = config.heart_spacing

   -- Logic: 1 Heart = 10 HP.
   local hp_per_heart = 10

   local max_hp = player.max_hp
   local current_hp = player.hp
   local overheal = player.overflow_hp or 0

   local base_hearts = ceil(max_hp / hp_per_heart)
   local overheal_hearts = ceil(overheal / hp_per_heart)

   -- Wrapping Constants
   local MAX_PER_ROW = config.max_per_row or 10
   local row = 0
   local col = 0

   -- Helper to calculate position and advance counters
   local function get_pos_and_advance()
      -- Calculate position based on current row/col
      local heart_x = x + (col * spacing)
      local heart_y = y + (row * spacing)

      -- Advance counters
      col = col + 1
      if col >= MAX_PER_ROW then
         col = 0
         row = row + 1
      end

      return heart_x, heart_y
   end

   -- Draw Base Hearts
   for i = 0, base_hearts - 1 do
      local heart_x, heart_y = get_pos_and_advance()

      local hp_in_heart = min(hp_per_heart, max(0, current_hp - (i * hp_per_heart)))

      if hp_in_heart >= 10 then
         -- Full
         draw_heart_sprite(heart_x, heart_y, "full", config, config.colors.normal)
      elseif hp_in_heart >= 5 then
         -- Half
         -- Draw empty backing first, then half on top
         draw_heart_sprite(heart_x, heart_y, "empty", config, config.colors.empty)
         draw_heart_sprite(heart_x, heart_y, "half", config, config.colors.normal)
      else
         -- Empty
         draw_heart_sprite(heart_x, heart_y, "empty", config, config.colors.empty)
      end
   end

   -- Draw Overheal Hearts (Blue)
   for i = 0, overheal_hearts - 1 do
      local heart_x, heart_y = get_pos_and_advance()

      local hp_in_heart = min(hp_per_heart, max(0, overheal - (i * hp_per_heart)))

      if hp_in_heart >= 10 then
         draw_heart_sprite(heart_x, heart_y, "full", config, config.colors.overheal)
      elseif hp_in_heart >= 5 then
         -- Half Overheal
         draw_heart_sprite(heart_x, heart_y, "half", config, config.colors.overheal)
      end
   end
end

return HealthBar
