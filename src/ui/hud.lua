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
   local spacing = config.spacing_x

   -- Draw Coins
   Rendering.draw_outlined(config.sprites.coins, x, y, config.shadow_color)
   local coin_str = string.format("%02d", player.coins or 0)
   print_shadowed(coin_str, x + config.text_offset_x, y + config.text_offset_y, config.text_color, config.shadow_color)

   -- Draw Bombs
   x += spacing
   Rendering.draw_outlined(config.sprites.bombs, x, y, config.shadow_color)
   local bomb_str = string.format("%02d", player.bombs or 0)
   print_shadowed(bomb_str, x + config.text_offset_x, y + config.text_offset_y, config.text_color, config.shadow_color)

   -- Draw Keys
   x += spacing
   Rendering.draw_outlined(config.sprites.keys, x, y, config.shadow_color)
   local key_str = string.format("%02d", player.keys or 0)
   print_shadowed(key_str, x + config.text_offset_x, y + config.text_offset_y, config.text_color, config.shadow_color)
end

-- Draw shop item price tags (called in world-space before camera reset)
-- @param shop_world - The ECS world to query for shop items
function Hud.draw_shop_prices(shop_world)
   shop_world.sys("shop_item,drawable", function(item)
      if item.purchased then return end

      local price = item.price or 10
      local price_str = "$"..price
      local text_x = item.x + 8 - #price_str * 2 -- Center text (each char ~4px)
      local text_y = item.y + 18                 -- Below the item

      -- Draw price with shadow
      print(price_str, text_x + 1, text_y + 1, 0) -- Shadow
      print(price_str, text_x, text_y, 10)        -- Yellow text

      -- Draw item name above
      if item.item_name then
         local name_x = item.x + 8 - #item.item_name * 2
         local name_y = item.y - 8
         print(item.item_name, name_x + 1, name_y + 1, 0) -- Shadow
         print(item.item_name, name_x, name_y, 7)         -- White text
      end
   end)()
end

return Hud
