-- XP Bar UI component
-- Renders XP progress bar at the bottom of the screen
local GameConstants = require("src/game/game_config")

local XpBar = {}

-- Helper to draw text with shadow for readability
local function print_shadowed(str, x, y, col, shadow_col)
   print(str, x + 1, y + 1, shadow_col or 1)
   print(str, x, y, col)
end

-- Draw the XP bar
-- @param player - The player entity to read XP stats from
function XpBar.draw(player)
   if not player then return end

   local config = GameConstants.Hud.xp_bar
   local screen_width = SCREEN_WIDTH -- Picotron screen width

   -- Calculate bar dimensions
   local bar_height = config.height or 6
   local bar_x = config.x or 4
   local bar_y = config.y or 256
   local bar_width = config.width or screen_width - (bar_x * 2)

   -- Calculate fill percentage
   local xp = player.xp or 0
   local xp_needed = player.xp_to_next_level or GameConstants.Player.base_xp_to_level
   local fill_percent = xp / xp_needed
   if fill_percent > 1 then fill_percent = 1 end
   local fill_width = math.floor(bar_width * fill_percent)

   -- Draw background
   rectfill(bar_x, bar_y, bar_x + bar_width, bar_y + bar_height, config.bg_color or 1)

   -- Draw fill
   if fill_width > 0 then
      rectfill(bar_x + 1, bar_y + 1, bar_x + fill_width - 1, bar_y + bar_height - 1, config.fill_color or 10)
   end

   -- Draw border
   rect(bar_x, bar_y, bar_x + bar_width, bar_y + bar_height, config.border_color or 5)

   -- Draw level text (inside the bar, left aligned)
   local level_text = "Lv."..tostring(player.level or 1)
   print_shadowed(level_text, bar_x + 4, bar_y + 1, config.text_color or 7, 0)

   -- Draw XP text (inside the bar, right aligned)
   local xp_text = xp.."/"..xp_needed.." XP"
   local text_width = #xp_text * 4
   print_shadowed(xp_text, bar_x + bar_width - text_width - 8, bar_y + 1, config.text_color or 7, 0)
end

return XpBar
