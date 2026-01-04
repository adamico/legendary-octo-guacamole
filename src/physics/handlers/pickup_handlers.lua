-- Pickup collision handlers
-- Handles Player collecting pickups (coins, keys, bombs, health)

local Effects = require("src/systems/effects")
local FloatingText = require("src/systems/floating_text")
local GameConstants = require("src/game/game_config")

local PickupHandlers = {}

-- Mutation application logic
local function apply_mutation(player, mutation_name)
   if mutation_name == "Eggsaggerated" then
      -- Chances: = 0.75, 0.125, 0.125
      player.roll_dud_chance = 0.75
      player.roll_hatch_chance = 0.125
      -- Remainder is Leech (0.125)

      -- Double dud damage
      local base_dud = GameConstants.Player.dud_damage
      player.dud_damage = (player.dud_damage or base_dud) * 2
   elseif mutation_name == "Broodmother" then
      -- Chances: = 0.125, 0.75, 0.125
      player.roll_dud_chance = 0.125
      player.roll_hatch_chance = 0.75
      -- Remainder is Leech (0.125)

      -- Double base chick minions stats (via flag)
      player.broodmother_active = true
   elseif mutation_name == "Pureblood" then
      -- Chances: = 0.125, 0.125, 0.75
      player.roll_dud_chance = 0.125
      player.roll_hatch_chance = 0.125
      -- Remainder is Leech (0.75)

      -- Increase regen_rate = 3
      player.regen_rate = 3

      -- Damage reduction = 20% (multiplier 0.8)
      player.damage_reduction = (player.damage_reduction or 1.0) * 0.8

      -- Melee bonus damage = 10
      player.melee_bonus_damage = (player.melee_bonus_damage or 0) + 10

      -- Allow melee attacks at 1/2 max health
      player.melee_threshold_ratio = 0.5
   end

   player.mutations = player.mutations or GameConstants.Player.mutations
   player.mutations[mutation_name] += 1
end

-- Pickup effect registry (maps pickup_effect string -> handler function)
local PickupEffects = {}

PickupEffects.coin = function(player, pickup)
   local amount = pickup.amount or 1
   player.coins = (player.coins or 0) + amount
   -- REFACTOR: Use SoundManager.play("pickup") or similar
   sfx(6) -- pickup sound
   FloatingText.spawn_at_entity(player, amount, "pickup", pickup.sprite_index)
end

PickupEffects.key = function(player, pickup)
   local amount = pickup.amount or 1
   player.keys = (player.keys or 0) + amount
   -- REFACTOR: Use SoundManager.play("pickup") or similar
   sfx(6) -- pickup sound
   FloatingText.spawn_at_entity(player, amount, "pickup", pickup.sprite_index)
end

PickupEffects.bomb = function(player, pickup)
   local amount = pickup.amount or 1
   player.bombs = (player.bombs or 0) + amount
   -- REFACTOR: Use SoundManager.play("pickup") or similar
   sfx(6) -- pickup sound
   FloatingText.spawn_at_entity(player, amount, "pickup", pickup.sprite_index)
end

PickupEffects.health = function(player, pickup)
   local heal_amount = pickup.recovery_amount or 16
   player.hp = player.hp + heal_amount

   if player.hp > player.max_hp then
      player.overflow_hp = (player.overflow_hp or 0) + (player.hp - player.max_hp)
      player.hp = player.max_hp
   end
   -- REFACTOR: Use SoundManager.play("pickup") or similar
   sfx(6) -- pickup sound
   FloatingText.spawn_at_entity(player, heal_amount, "heal", pickup.sprite_index)
end

PickupEffects.xp = function(player, pickup)
   local amount = pickup.xp_amount or 10
   player.xp = (player.xp or 0) + amount
   -- REFACTOR: Use SoundManager.play("pickup") or similar
   sfx(6) -- pickup sound
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

-- Handler for Mutation pickup
local function handle_mutation_pickup(player, mutation)
   if mutation.collected then return end
   mutation.collected = true

   local name = mutation.mutation -- Defined in config
   if name then
      apply_mutation(player, name)
      FloatingText.spawn_at_entity(player, name.." Mutation +1", "pickup")
   end

   Effects.pickup_collect(mutation)
   world.del(mutation)
end

-- Register all pickup handlers
function PickupHandlers.register(handlers)
   handlers.entity["Player,HealthPickup"] = handle_pickup_collection
   handlers.entity["Player,Coin"] = handle_pickup_collection
   handlers.entity["Player,Key"] = handle_pickup_collection
   handlers.entity["Player,Bomb"] = handle_pickup_collection
   handlers.entity["Player,DNAStrand"] = handle_pickup_collection
   handlers.entity["Player,Mutation"] = handle_mutation_pickup
end

return PickupHandlers
