local GameConstants = require("src/game/game_config")
local Rendering = require("src/systems/rendering")

local Hud = {}

-- Helper to draw text with shadow
local function print_shadowed(str, x, y, col, shadow_col)
   print(str, x + 1, y + 1, shadow_col)
   print(str, x, y, col)
end

-- Draw the inventory HUD
-- @param player - The player entity to read stats from
function Hud.draw(player)
   if not player then return end

   local config = GameConstants.Hud.inventory
   local x = config.x
   local y = config.y
   local spacing = config.spacing_y

   -- Draw Coins
   Rendering.draw_outlined(config.sprites.coins, x, y, config.shadow_color)
   local coin_str = string.format("%02d", player.coins or 0)
   print_shadowed(coin_str, x + config.text_offset_x, y + config.text_offset_y, config.text_color, config.shadow_color)

   -- Draw Bombs
   y = y + spacing
   Rendering.draw_outlined(config.sprites.bombs, x, y, config.shadow_color)
   local bomb_str = string.format("%02d", player.bombs or 0)
   print_shadowed(bomb_str, x + config.text_offset_x, y + config.text_offset_y, config.text_color, config.shadow_color)

   -- Draw Keys
   y = y + spacing
   Rendering.draw_outlined(config.sprites.keys, x, y, config.shadow_color)
   local key_str = string.format("%02d", player.keys or 0)
   print_shadowed(key_str, x + config.text_offset_x, y + config.text_offset_y, config.text_color, config.shadow_color)
end

return Hud
