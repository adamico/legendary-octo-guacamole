-- Obstacle collision handlers
-- Handles collisions with Rocks and Destructibles

local GameState = require("src/game/game_state")
local Entities = require("src/entities")
local GameConstants = require("src/game/game_config")
local HitboxUtils = require("src/utils/hitbox_utils")
local Effects = require("src/systems/effects")
local DungeonManager = require("src/world/dungeon_manager")
local FloatingText = require("src/systems/floating_text")
local qsort = require("lib/qsort")

local ObstacleHandlers = {}

-- Loot table for destructibles (weights must sum to 1.0)
local DESTRUCTIBLE_LOOT = {
   {type = "Coin", weight = 0.55},
   {type = "Bomb", weight = 0.30},
   {type = "Key",  weight = 0.15},
}

-- Helper: Pick a random loot type from weighted table
local function pick_loot(loot_table)
   local roll = rnd()
   local cumulative = 0
   for _, entry in ipairs(loot_table) do
      cumulative = cumulative + entry.weight
      if roll < cumulative then
         return entry.type
      end
   end
   return loot_table[#loot_table].type -- Fallback to last entry
end

-- Helper: Destroy a destructible entity
local function destroy_destructible(destructible, attacker)
   if destructible.dead then return end

   destructible.dead = true
   world.del(destructible)

   -- 30% chance to spawn loot
   if rnd() < 0.3 then
      local cx = destructible.x + destructible.width / 2
      local cy = destructible.y + destructible.height / 2
      local loot_type = pick_loot(DESTRUCTIBLE_LOOT)

      -- Snap to floor to avoid pits
      local sx, sy = DungeonManager.snap_to_nearest_floor(cx, cy, DungeonManager.current_room)
      if sx then cx, cy = sx, sy end

      Entities.spawn_pickup(world, cx, cy, loot_type)
   end
end

-- Helper: Destroy a rock entity (normally indestructible, but explosions can break them)
local function destroy_rock(rock)
   if rock.dead then return end

   rock.dead = true
   world.del(rock)
end

-- Loot table for chests (weights must sum to 1.0)
local CHEST_LOOT = {
   {type = "Coin",         weight = 0.40},
   {type = "Bomb",         weight = 0.25},
   {type = "Key",          weight = 0.15},
   {type = "HealthPickup", weight = 0.20},
}

--- Helper: Open a chest entity and spawn loot
--- @param chest The chest entity
--- @param player The player entity (for key checking on locked chests)
--- @return true if chest was opened, false if locked and no key
local function open_chest(chest, player)
   if chest.dead or chest.opened then return false end

   -- Check if locked and player has keys
   if chest.is_locked and not GameState.cheats.infinite_inventory then
      local key_cost = chest.key_cost or 1
      if not player.keys or player.keys < key_cost then
         -- Not enough keys - cannot open
         return false
      end
      -- Consume key(s)
      player.keys = player.keys - key_cost
   end

   chest.opened = true

   -- Special handling for Treasure Chest (mutations)
   if chest.is_chest and chest.mutation then
      local cx = chest.x + chest.width / 2
      local cy = chest.y + chest.height / 2
      local spawn_x = cx - 8
      local spawn_y = cy - 8 -- Center the 16x16 mutation item

      -- Spawn the specific Mutation entity
      -- We use spawn_pickup generic or we need a specific spawner?
      -- The mutation name is in chest.mutation (e.g. "Eggsaggerated")
      -- We need to spawn an entity of type "Mutation" with mutation=chest.mutation

      -- Zelda-style item rise animation
      Effects.spawn_item_rise(world, spawn_x, spawn_y, chest.mutation_sprite, chest.mutation, function(anim_ent)
         -- On finish: Spawn the actual pickup
         local pickup = Entities.spawn_pickup(world, anim_ent.x, anim_ent.y, "Mutation", {
            mutation = chest.mutation,
            sprite_index = chest.mutation_sprite
         })
         -- Small bounce/drop effect upon landing
         if pickup then
            pickup.vel_y = -1
         end
      end)

      -- Treasure chests don't drop random loot
   else
      -- Normal loot logic for regular chests
      -- Get loot parameters from config
      local loot_min = chest.loot_min or 1
      local loot_max = chest.loot_max or 3
      local loot_count = loot_min + flr(rnd(loot_max - loot_min + 1))

      -- Calculate spawn position (center of chest)
      local cx = chest.x + chest.width / 2
      local cy = chest.y + chest.height / 2

      -- Track spawned positions to avoid overlap
      local spawned_positions = {}
      local MIN_SEPARATION = 14 -- Minimum distance between spawned items

      for i = 1, loot_count do
         local loot_type = pick_loot(CHEST_LOOT)

         -- Spread pickups in a circle pattern with consistent angles
         local angle = (i / loot_count) * 6.28
         local base_dist = 16 + (i - 1) * 4 -- Stagger distances: 16, 20, 24, etc.
         local spawn_x = cx + cos(angle) * base_dist - 8
         local spawn_y = cy + sin(angle) * base_dist - 8

         -- Snap to floor to avoid pits
         local sx, sy = DungeonManager.snap_to_nearest_floor(spawn_x, spawn_y, DungeonManager.current_room)
         if sx then
            spawn_x, spawn_y = sx, sy
         else
            -- Fallback to chest center if no valid floor found
            spawn_x, spawn_y = cx - 8, cy - 8
         end

         -- Check for overlap with previously spawned items and nudge if needed
         for _, pos in ipairs(spawned_positions) do
            local dx, dy = spawn_x - pos.x, spawn_y - pos.y
            local dist = sqrt(dx * dx + dy * dy)
            if dist < MIN_SEPARATION and dist > 0 then
               -- Nudge away from existing item
               local nudge = (MIN_SEPARATION - dist) / dist
               spawn_x = spawn_x + dx * nudge
               spawn_y = spawn_y + dy * nudge
            elseif dist == 0 then
               -- Exactly same position, offset randomly
               spawn_x = spawn_x + rnd(MIN_SEPARATION) - MIN_SEPARATION / 2
               spawn_y = spawn_y + rnd(MIN_SEPARATION) - MIN_SEPARATION / 2
            end
         end

         table.insert(spawned_positions, {x = spawn_x, y = spawn_y})
         Entities.spawn_pickup(world, spawn_x, spawn_y, loot_type)
      end
   end

   -- Change sprite to open chest (if configured)
   if chest.sprite_open then
      chest.sprite_index = chest.sprite_open
   end

   -- Mark as dead and delete
   chest.dead = true
   world.del(chest)

   return true
end


--- Push entity out of obstacle (AABB minimum penetration resolution)
---
--- Respects solid tiles - won't push entity into walls
---
--- @param entity The entity to push out of the obstacle
--- @param obstacle The obstacle to push the entity out of
local function push_out(entity, obstacle)
   local e_hb = HitboxUtils.get_hitbox(entity)
   local o_hb = HitboxUtils.get_hitbox(obstacle)

   -- Calculate overlap on each axis
   local overlap_left = (e_hb.x + e_hb.w) - o_hb.x
   local overlap_right = (o_hb.x + o_hb.w) - e_hb.x
   local overlap_top = (e_hb.y + e_hb.h) - o_hb.y
   local overlap_bottom = (o_hb.y + o_hb.h) - e_hb.y

   -- Build sorted list of push options by penetration depth (smallest first)
   local push_options = {
      {overlap = overlap_left,   px = -overlap_left, py = 0},
      {overlap = overlap_right,  px = overlap_right, py = 0},
      {overlap = overlap_top,    px = 0,             py = -overlap_top},
      {overlap = overlap_bottom, px = 0,             py = overlap_bottom},
   }
   qsort(push_options, function(a, b) return a.overlap < b.overlap end)

   -- Find first push option that doesn't collide with solid tiles
   local Collision = require("src/physics/collision")
   for _, opt in ipairs(push_options) do
      local new_hb_x = e_hb.x + opt.px
      local new_hb_y = e_hb.y + opt.py
      if not Collision.is_solid(new_hb_x, new_hb_y, e_hb.w, e_hb.h, entity) then
         -- Apply push to entity position
         entity.x = entity.x + opt.px
         entity.y = entity.y + opt.py

         -- Zero velocity in push direction to prevent jittering
         if opt.px ~= 0 then entity.vel_x = 0 end
         if opt.py ~= 0 then entity.vel_y = 0 end
         return
      end
   end

   -- All directions blocked - entity is trapped, don't push
   -- This prevents phasing through walls
end

--- Push enemy out of obstacle and handle Dasher stun
---
--- @param enemy The enemy to push out of the obstacle
--- @param obstacle The obstacle to push the enemy out of
local function push_out_enemy(enemy, obstacle)
   if world.msk(enemy).flying then return end
   push_out(enemy, obstacle)

   -- Special case: Dasher behavior on obstacle collision
   if enemy.enemy_type == "Dasher" and enemy.dasher_fsm then
      if enemy.dasher_fsm:is("dash") then
         -- Stun when dashing into obstacle
         enemy.dasher_collision = true
      elseif enemy.dasher_fsm:is("patrol") then
         -- Treat obstacle like a wall during patrol so Dasher can change direction
         -- This prevents Dashers from getting stuck against obstacles
         enemy.hit_wall = true
      end
   end
end

--- Helper: handle egg break on obstacle collision
--- Guards against being called multiple times for the same projectile
---
--- @param projectile The projectile to handle
--- @param obstacle_type The type of obstacle the projectile hit
local function projectile_hit_obstacle(projectile, obstacle_type)
   -- Prevent double processing if projectile hits multiple obstacles in same frame
   if projectile.hit_obstacle then return end
   projectile.hit_obstacle = true

   -- Use hitbox center for spawn position
   local hb = HitboxUtils.get_hitbox(projectile)
   local spawn_x = hb.x + hb.w / 2 - 8
   local spawn_y = hb.y + hb.h / 2 - 8

   if obstacle_type == "Rock" then
      -- Hard Obstacle: Spawns Yolk Splat (same as wall)
      Entities.spawn_minion(world, spawn_x, spawn_y, "YolkSplat", {
         creation_time = t(),
         lifespan = GameConstants.Player.yolk_splat_duration or 300,
         yolk_slow_factor = GameConstants.Player.yolk_slow_factor or 0.7,
      })
   elseif obstacle_type == "Destructible" then
      -- Soft Destructible: Break immediate. egg destroyed.
      -- No hatch, no splat. Just deletion.
      Effects.spawn_visual_effect(world, spawn_x, spawn_y, 29, 15) -- Broken egg visual
   end

   world.del(projectile)
end

--- Register all obstacle handlers
---
--- @param handlers The handlers table to register the obstacle handlers to
function ObstacleHandlers.register(handlers)
   -- Player/Enemy push-out
   handlers.entity["Player,Rock"] = function(player, rock) push_out(player, rock) end
   handlers.entity["Player,Destructible"] = function(player, dest) push_out(player, dest) end
   handlers.entity["Enemy,Rock"] = push_out_enemy
   handlers.entity["Enemy,Destructible"] = push_out_enemy

   -- Chick (Minions) vs Obstacles
   handlers.entity["Chick,Rock"] = function(chick, rock) push_out(chick, rock) end
   handlers.entity["Chick,Destructible"] = function(chick, dest) push_out(chick, dest) end

   -- Chick vs Enemy (one-sided push: only move chick, not enemy)
   handlers.entity["Chick,Enemy"] = function(chick, enemy) push_out(chick, enemy) end
   handlers.entity["Enemy,Chick"] = function(enemy, chick) push_out(chick, enemy) end

   -- Player vs Chests (touching opens them)
   handlers.entity["Player,Chest"] = function(player, chest)
      push_out(player, chest)
      open_chest(chest, player)
   end
   handlers.entity["Player,LockedChest"] = function(player, chest)
      push_out(player, chest)
      open_chest(chest, player)
   end
   handlers.entity["Player,TreasureChest"] = function(player, chest)
      push_out(player, chest)
      open_chest(chest, player)
   end

   -- Chick vs Chests (push out only, can't open)
   handlers.entity["Chick,Chest"] = function(chick, chest) push_out(chick, chest) end
   handlers.entity["Chick,LockedChest"] = function(chick, chest) push_out(chick, chest) end
   handlers.entity["Chick,TreasureChest"] = function(chick, chest) push_out(chick, chest) end

   -- Enemy vs Chests (push out only)
   handlers.entity["Enemy,Chest"] = push_out_enemy
   handlers.entity["Enemy,LockedChest"] = push_out_enemy
   handlers.entity["Enemy,TreasureChest"] = push_out_enemy

   -- Melee vs Chest (opens chest)
   handlers.entity["MeleeHitbox,Chest"] = function(hitbox, chest)
      -- Find player to access keys for locked chests
      local player = nil
      world.sys("player", function(p) player = p end)()
      if player then
         open_chest(chest, player)
      end
   end
   handlers.entity["MeleeHitbox,LockedChest"] = function(hitbox, chest)
      local player = nil
      world.sys("player", function(p) player = p end)()
      if player then
         open_chest(chest, player)
      end
   end
   handlers.entity["MeleeHitbox,TreasureChest"] = function(hitbox, chest)
      local player = nil
      world.sys("player", function(p) player = p end)()
      if player then
         open_chest(chest, player)
      end
   end

   -- Melee vs Destructible
   handlers.entity["MeleeHitbox,Destructible"] = function(hitbox, destructible)
      destroy_destructible(destructible, hitbox.owner_entity)
   end

   -- Projectile vs Rock
   handlers.entity["Projectile,Rock"] = function(projectile, rock)
      projectile_hit_obstacle(projectile, "Rock")
   end

   -- Projectile vs Destructible
   handlers.entity["Projectile,Destructible"] = function(projectile, destructible)
      destroy_destructible(destructible, projectile)
      projectile_hit_obstacle(projectile, "Destructible")
   end

   -- EnemyProjectile vs Rock (no pickup)
   handlers.entity["EnemyProjectile,Rock"] = function(projectile, rock)
      world.del(projectile)
   end

   -- EnemyProjectile vs Destructible
   handlers.entity["EnemyProjectile,Destructible"] = function(projectile, destructible)
      destroy_destructible(destructible, projectile)
      world.del(projectile)
   end

   -- Projectile vs Chest (opens chest)
   handlers.entity["Projectile,Chest"] = function(projectile, chest)
      local player = nil
      world.sys("player", function(p) player = p end)()
      if player then
         open_chest(chest, player)
      end
      projectile_hit_obstacle(projectile, "Destructible") -- Use destructible behavior (break egg)
   end
   handlers.entity["Projectile,LockedChest"] = function(projectile, chest)
      local player = nil
      world.sys("player", function(p) player = p end)()
      if player then
         open_chest(chest, player) -- Will check for key
      end
      projectile_hit_obstacle(projectile, "Destructible")
   end

   -- EnemyProjectile vs Chest (just deletes projectile, doesn't open)
   handlers.entity["EnemyProjectile,Chest"] = function(projectile, chest)
      world.del(projectile)
   end
   handlers.entity["EnemyProjectile,LockedChest"] = function(projectile, chest)
      world.del(projectile)
   end

   -- Explosion vs Destructible (bombs destroy destructibles)
   handlers.entity["Explosion,Destructible"] = function(explosion, destructible)
      destroy_destructible(destructible, explosion)
   end

   -- Explosion vs Chest: Do nothing (bombs should not destroy chests)
   handlers.entity["Explosion,Chest"] = function(explosion, chest)
      -- Intentionally empty: bombs don't affect chests
   end
   handlers.entity["Explosion,LockedChest"] = function(explosion, chest)
      -- Intentionally empty: bombs don't affect locked chests
   end

   -- Explosion vs Rock (bombs are the only way to destroy rocks)
   handlers.entity["Explosion,Rock"] = function(explosion, rock)
      destroy_rock(rock)
   end

   -- Shop Item purchase handlers
   handlers.entity["Player,ShopItem"] = function(player, shop_item)
      -- Guard: Already purchased
      if shop_item.purchased then return end

      -- Push player out first
      push_out(player, shop_item)

      local price = shop_item.price or 10

      -- Check if infinite inventory cheat is active (free purchases)
      local free_purchase = GameState.cheats.infinite_inventory

      if not free_purchase and (player.coins or 0) < price then
         -- Not enough coins - silently reject
         return
      end

      -- Deduct coins (unless using infinite inventory cheat)
      if not free_purchase then
         player.coins = (player.coins or 0) - price
      end
      shop_item.purchased = true

      -- Apply item effect
      if shop_item.apply_fn then
         shop_item.apply_fn(player)
      end

      -- Visual feedback
      FloatingText.spawn_at_entity(player, shop_item.item_name or "Purchased!", "pickup")

      -- Remove from world
      world.del(shop_item)
   end

   -- Other entities vs ShopItem (push out only)
   handlers.entity["Enemy,ShopItem"] = push_out_enemy
   handlers.entity["Chick,ShopItem"] = function(chick, shop_item) push_out(chick, shop_item) end
   handlers.entity["Projectile,ShopItem"] = function(projectile, shop_item)
      projectile_hit_obstacle(projectile, "Rock")
   end
   handlers.entity["EnemyProjectile,ShopItem"] = function(projectile, shop_item)
      world.del(projectile)
   end

   -- Pickup vs Pickup -> push apart to prevent stacking
   local pickup_types = {"Coin", "Key", "Bomb", "HealthPickup"}
   for _, type1 in ipairs(pickup_types) do
      for _, type2 in ipairs(pickup_types) do
         handlers.entity[type1..","..type2] = function(p1, p2)
            -- Push pickups apart to prevent stacking
            local dx = p1.x - p2.x
            local dy = p1.y - p2.y
            local dist = sqrt(dx * dx + dy * dy)
            if dist < 1 then
               dx, dy = rnd() - 0.5, rnd() - 0.5
               dist = 1
            end
            local push_dist = 4 -- Increased from 2 for faster separation
            p1.x = p1.x + (dx / dist) * push_dist
            p1.y = p1.y + (dy / dist) * push_dist
         end
      end
   end
end

return ObstacleHandlers
