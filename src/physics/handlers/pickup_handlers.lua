-- Pickup collision handlers
-- Handles Player collecting pickups (coins, keys, bombs, health)

local Effects = require("src/systems/effects")
local FloatingText = require("src/systems/floating_text")

local PickupHandlers = {}

-- Pickup effect registry (maps pickup_effect string -> handler function)
local PickupEffects = {}

PickupEffects.coin = function(player, pickup)
   local amount = pickup.amount or 1
   player.coins = (player.coins or 0) + amount
   FloatingText.spawn_at_entity(player, amount, "pickup", pickup.sprite_index)
end

PickupEffects.key = function(player, pickup)
   local amount = pickup.amount or 1
   player.keys = (player.keys or 0) + amount
   FloatingText.spawn_at_entity(player, amount, "pickup", pickup.sprite_index)
end

PickupEffects.bomb = function(player, pickup)
   local amount = pickup.amount or 1
   player.bombs = (player.bombs or 0) + amount
   FloatingText.spawn_at_entity(player, amount, "pickup", pickup.sprite_index)
end

PickupEffects.health = function(player, pickup)
   local heal_amount = pickup.recovery_amount or 16
   player.hp = player.hp + heal_amount

   if player.hp > player.max_hp then
      player.overflow_hp = (player.overflow_hp or 0) + (player.hp - player.max_hp)
      player.hp = player.max_hp
   end

   FloatingText.spawn_at_entity(player, heal_amount, "heal", pickup.sprite_index)
end

PickupEffects.xp = function(player, pickup)
   local amount = pickup.xp_amount or 10
   player.xp = (player.xp or 0) + amount
   -- Note: Floating text intentionally omitted per design
end

-- Unified pickup collection handler
local function handle_pickup_collection(player, pickup)
   -- Guard: Prevent double collection (pickup may be touched multiple frames)
   if pickup.collected then return end

   pickup.collected = true

   local effect_type = pickup.pickup_effect or "health"
   local effect_handler = PickupEffects[effect_type]
   assert(effect_handler, "Unknown pickup_effect '"..effect_type.."'")(player, pickup)

   Effects.pickup_collect(pickup)
   world.del(pickup)
end

-- Register all pickup handlers
function PickupHandlers.register(handlers)
   handlers.entity["Player,HealthPickup"] = handle_pickup_collection
   handlers.entity["Player,Coin"] = handle_pickup_collection
   handlers.entity["Player,Key"] = handle_pickup_collection
   handlers.entity["Player,Bomb"] = handle_pickup_collection
   handlers.entity["Player,DNAStrand"] = handle_pickup_collection
end

return PickupHandlers
