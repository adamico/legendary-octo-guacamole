-- Shop Item Pool Configuration
-- Defines purchasable items available in shop rooms

local ShopItems = {}
local FloatingText = require("src/systems/floating_text")

-- All purchasable items
ShopItems.pool = {
   {
      id = "heart_container",
      name = "Heart Container",
      description = "+10 Max HP",
      price = 15,
      sprite = 56,
      apply = function(player)
         player.max_hp += 10
         player.hp = math.min(player.hp + 10, player.max_hp)
         FloatingText.spawn_at_entity(player, 1, "heal", 56)
      end
   },
   {
      id = "bomb_pack",
      name = "Bomb Pack",
      description = "+3 Bombs",
      price = 5,
      sprite = 38,
      apply = function(player)
         player.bombs = (player.bombs or 0) + 3
         FloatingText.spawn_at_entity(player, 3, "bomb", 38)
      end
   },
   {
      id = "key_ring",
      name = "Key Ring",
      description = "+2 Keys",
      price = 8,
      sprite = 39,
      apply = function(player)
         player.keys = (player.keys or 0) + 2
         FloatingText.spawn_at_entity(player, 2, "key", 39)
      end
   },
}

-- Pick N unique random items from pool
function ShopItems.pick_random_items(count)
   local available = {}
   for _, item in ipairs(ShopItems.pool) do
      add(available, item)
   end

   local selected = {}
   for i = 1, count do
      if #available == 0 then break end
      local idx = flr(rnd(#available)) + 1
      add(selected, available[idx])
      deli(available, idx)
   end

   return selected
end

return ShopItems
