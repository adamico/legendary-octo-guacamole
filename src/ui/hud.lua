local GameConstants = require("src/game/game_config")
local Rendering = require("src/systems/rendering")
local HitboxUtils = require("src/utils/hitbox_utils")

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

-- Draw boss health bar at top of screen
-- @param world - The ECS world to query for boss entities
function Hud.draw_boss_health(world)
   -- Find boss entity
   local boss = nil
   world.sys("boss,health", function(e)
      if not e.dead then
         boss = e
      end
   end)()

   if not boss then return end

   -- Health bar config
   local bar_width = 200
   local bar_height = 12
   local bar_x = (SCREEN_WIDTH - bar_width) / 2
   local bar_y = 26

   -- Background (dark)
   rectfill(bar_x - 2, bar_y - 2, bar_x + bar_width + 1, bar_y + bar_height + 1, 0)

   -- Border
   rect(bar_x - 1, bar_y - 1, bar_x + bar_width, bar_y + bar_height, 5)

   -- Health fill
   local hp_ratio = (boss.hp or 0) / (boss.max_hp or 1)
   local fill_width = flr(bar_width * hp_ratio)

   -- Color based on phase (green -> yellow -> red)
   local fill_color = 11 -- Green
   if hp_ratio <= 0.33 then
      fill_color = 8     -- Red for phase 3
   elseif hp_ratio <= 0.66 then
      fill_color = 10    -- Yellow for phase 2
   end

   if fill_width > 0 then
      rectfill(bar_x, bar_y, bar_x + fill_width - 1, bar_y + bar_height - 1, fill_color)
   end

   -- Phase indicators (tick marks at 33% and 66%)
   local phase2_x = bar_x + flr(bar_width * 0.66)
   local phase3_x = bar_x + flr(bar_width * 0.33)
   line(phase2_x, bar_y, phase2_x, bar_y + bar_height - 1, 0)
   line(phase3_x, bar_y, phase3_x, bar_y + bar_height - 1, 0)

   -- Boss name
   local name = "GREEN WITCH"
   local name_x = (SCREEN_WIDTH - #name * 4) / 2
   print(name, name_x + 1, bar_y + bar_height + 4, 0) -- Shadow
   print(name, name_x, bar_y + bar_height + 3, 7)     -- White
end

local function draw_target_indicator(entity)
   if not entity.flee_target_x or not entity.flee_target_y then return end

   -- Blinking effect: toggle visibility every 20 frames
   local frame = entity.boss_timer or 0
   if frame % 20 < 12 then
      local scale = 2
      local sprite = SPAWNER_INDICATOR_SPRITE
      sspr(
         sprite,
         0, 0,
         16, 16,
         entity.flee_target_x, entity.flee_target_y,
         16 * scale, 16 * scale
      )
   end
end

local function draw_trajectory_indicator(entity)
   local is_moving = entity.vel_x ~= 0 or entity.vel_y ~= 0
   local has_target = entity.flee_target_x
   if not is_moving or not has_target then return end

   -- Get center position (get_center returns two values, not a table)
   local cx, cy = HitboxUtils.get_center(entity)
   -- Target center (add 16 to center on 32x32 indicator sprite)
   local tx = entity.flee_target_x + 16
   local ty = entity.flee_target_y + 16

   -- Draw thick line using multiple parallel lines
   local thickness = 3
   for i = -thickness, thickness do
      line(cx + i, cy, tx + i, ty, 8) -- Horizontal offset
      line(cx, cy + i, tx, ty + i, 8) -- Vertical offset
   end
end

-- Draw boss telegraphs (flee targets, attack indicators, trajectory)
-- Call in world-space (before camera reset)
function Hud.draw_boss_telegraphs(world)
   -- Find boss entity
   local boss = nil
   world.sys("boss,enemy", function(e)
      if not e.dead then
         boss = e
      end
   end)()

   if not boss then return end

   -- Draw trajectory first (behind other elements)
   draw_trajectory_indicator(boss)
   -- draw_target_indicator(boss)
end

return Hud
