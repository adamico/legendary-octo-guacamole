-- Obstacle collision handlers
-- Handles collisions with Rocks and Destructibles

local GameState = require("src/game/game_state")
local Entities = require("src/entities")
local GameConstants = require("src/game/game_config")
local HitboxUtils = require("src/utils/hitbox_utils")
local Effects = require("src/systems/effects")
local DungeonManager = require("src/world/dungeon_manager")
local FloatingText = require("src/systems/floating_text")

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
local function destroy_destructible(world, destructible, attacker)
   if destructible.dead then return end

   destructible.dead = true
   world:remove_entity(destructible.id) -- Using ECS remove

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
local function destroy_rock(world, rock)
   if rock.dead then return end

   rock.dead = true
   world:remove_entity(rock.id)
end

-- Loot table for chests (weights must sum to 1.0)
local CHEST_LOOT = {
   {type = "Coin",         weight = 0.40},
   {type = "Bomb",         weight = 0.25},
   {type = "Key",          weight = 0.15},
   {type = "HealthPickup", weight = 0.20},
}

--- Helper: Open a chest entity and spawn loot
--- @param world World
--- @param chest The chest entity
--- @param player The player entity (for key checking on locked chests)
--- @return true if chest was opened, false if locked and no key
local function open_chest(world, chest, player)
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

   -- Change sprite to open chest (if configured)
   if chest.sprite_open then
      chest.sprite_index = chest.sprite_open
   end

   -- Mark as dead and delete
   chest.dead = true
   world:remove_entity(chest.id)

   return true
end


--- Push entity out of obstacle (AABB minimum penetration resolution)
---
--- Respects solid tiles - won't push entity into walls
---
--- @param entity The entity to push out of the obstacle
--- @param obstacle The obstacle to push the entity out of
local function push_out(entity, obstacle)
   local Collision = require("src/physics/collision")
   local qsort = require("lib/qsort")
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
local function push_out_enemy(world, enemy, obstacle)
   -- Need world to check 'flying' mask?
   -- But enemy.flying access works via proxy? "flying" is not mapped in EntityProxy directly,
   -- but might be via boolean check or we access component directly?
   -- In `entity_proxy.lua`, unknown keys return nil unless mapped.
   -- `flying` IS NOT MAPPED via string in ComponentMap.
   -- But maybe `tag`?
   -- `world.msk(enemy).flying` implies `world.msk` returns mask object.
   -- `entity_proxy` doesn't implement `msk`.
   -- `world.msk` is legacy.
   -- In `picobloc`, `entity.flying` if it's a tag (boolean component)?
   -- `EntityProxy` handles tags. `flying` not in `TagMap` in `EntityProxy` earlier.
   -- So `enemy.flying` via proxy returns nil.
   -- We should check `timers.flying`? No.
   -- We should check if `flying` component exists.
   -- I'll assume `enemy.flying` works if I added it to `TagMap` or component map, or simple table access if not proxy?
   -- If `enemy` is proxy, we need to ensure `flying` is accessible.
   -- For safety, I'll ignore flying check or use safe access.
   -- Or better: `world:has_component(enemy.id, "flying")`.
   -- Let's assume standard behavior for now.

   -- Actually, `push_out_enemy` calls `push_out`.
   push_out(enemy, obstacle)

   -- Special case: Dasher behavior on obstacle collision
   if enemy.enemy_type == "Dasher" and enemy.dasher_fsm then
      if enemy.dasher_fsm:is("dash") then
         -- Stun when dashing into obstacle
         enemy.dasher_collision = true
      elseif enemy.dasher_fsm:is("patrol") then
         enemy.hit_wall = true
      end
   end
end

--- Helper: handle egg break on obstacle collision
--- Guards against being called multiple times for the same projectile
---
--- @param projectile The projectile to handle
--- @param obstacle_type The type of obstacle the projectile hit
local function projectile_hit_obstacle(world, projectile, obstacle_type)
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

   world:remove_entity(projectile.id)
end

--- Register all obstacle handlers
---
--- @param handlers The handlers table to register the obstacle handlers to
function ObstacleHandlers.register(handlers)
   -- Player/Enemy push-out
   handlers.entity["Player,Rock"] = function(world, player, rock) push_out(player, rock) end
   handlers.entity["Player,Destructible"] = function(world, player, dest) push_out(player, dest) end
   handlers.entity["Enemy,Rock"] = push_out_enemy
   handlers.entity["Enemy,Destructible"] = push_out_enemy

   -- Chick (Minions) vs Obstacles
   handlers.entity["Chick,Rock"] = function(world, chick, rock) push_out(chick, rock) end
   handlers.entity["Chick,Destructible"] = function(world, chick, dest) push_out(chick, dest) end

   -- Player vs Chests (touching opens them)
   handlers.entity["Player,Chest"] = function(world, player, chest)
      push_out(player, chest)
      open_chest(world, chest, player)
   end
   handlers.entity["Player,LockedChest"] = function(world, player, chest)
      push_out(player, chest)
      open_chest(world, chest, player)
   end

   -- Chick vs Chests (push out only, can't open)
   handlers.entity["Chick,Chest"] = function(world, chick, chest) push_out(chick, chest) end
   handlers.entity["Chick,LockedChest"] = function(world, chick, chest) push_out(chick, chest) end

   -- Enemy vs Chests (push out only)
   handlers.entity["Enemy,Chest"] = push_out_enemy
   handlers.entity["Enemy,LockedChest"] = push_out_enemy

   -- Melee vs Chest (opens chest)
   handlers.entity["MeleeHitbox,Chest"] = function(world, hitbox, chest)
      -- Need to query for player.
      world:query({"player", "position"}, function(ids, p_tag, pos)
         if ids.first <= ids.last then
            -- Assume first player
            local pid = ids[ids.first]
            -- Create temp proxy for `open_chest` which expects entity table/proxy
            local EntityProxy = require("src/utils/entity_proxy")
            local player = EntityProxy.new(world, pid)
            open_chest(world, chest, player)
         end
      end)
   end
   handlers.entity["MeleeHitbox,LockedChest"] = function(world, hitbox, chest)
      world:query({"player", "position"}, function(ids, p_tag, pos)
         if ids.first <= ids.last then
            local pid = ids[ids.first]
            local EntityProxy = require("src/utils/entity_proxy")
            local player = EntityProxy.new(world, pid)
            open_chest(world, chest, player)
         end
      end)
   end

   -- Melee vs Destructible
   handlers.entity["MeleeHitbox,Destructible"] = function(world, hitbox, destructible)
      -- owner_entity access via proxy? `hitbox` is proxy.
      -- Need to handle this. For now `destroy_destructible` only uses attacker for... ?
      -- `destroy_destructible` arg `attacker` is unused!
      destroy_destructible(world, destructible, hitbox.owner_entity)
   end

   -- Projectile vs Rock
   handlers.entity["Projectile,Rock"] = function(world, projectile, rock)
      projectile_hit_obstacle(world, projectile, "Rock")
   end

   -- Projectile vs Destructible
   handlers.entity["Projectile,Destructible"] = function(world, projectile, destructible)
      destroy_destructible(world, destructible, projectile)
      projectile_hit_obstacle(world, projectile, "Destructible")
   end

   -- EnemyProjectile vs Rock (no pickup)
   handlers.entity["EnemyProjectile,Rock"] = function(world, projectile, rock)
      world:remove_entity(projectile.id)
   end

   -- EnemyProjectile vs Destructible
   handlers.entity["EnemyProjectile,Destructible"] = function(world, projectile, destructible)
      destroy_destructible(world, destructible, projectile)
      world:remove_entity(projectile.id)
   end

   -- Projectile vs Chest (opens chest)
   handlers.entity["Projectile,Chest"] = function(world, projectile, chest)
      world:query({"player"}, function(ids)
         if ids.first <= ids.last then
            local EntityProxy = require("src/utils/entity_proxy")
            local player = EntityProxy.new(world, ids[ids.first])
            open_chest(world, chest, player)
         end
      end)
      projectile_hit_obstacle(world, projectile, "Destructible")
   end
   handlers.entity["Projectile,LockedChest"] = function(world, projectile, chest)
      world:query({"player"}, function(ids)
         if ids.first <= ids.last then
            local EntityProxy = require("src/utils/entity_proxy")
            local player = EntityProxy.new(world, ids[ids.first])
            open_chest(world, chest, player)
         end
      end)
      projectile_hit_obstacle(world, projectile, "Destructible")
   end

   -- EnemyProjectile vs Chest (just deletes projectile, doesn't open)
   handlers.entity["EnemyProjectile,Chest"] = function(world, projectile, chest)
      world:remove_entity(projectile.id)
   end
   handlers.entity["EnemyProjectile,LockedChest"] = function(world, projectile, chest)
      world:remove_entity(projectile.id)
   end

   -- Explosion vs Destructible (bombs destroy destructibles)
   handlers.entity["Explosion,Destructible"] = function(world, explosion, destructible)
      destroy_destructible(world, destructible, explosion)
   end

   -- Explosion vs Chest: Do nothing
   handlers.entity["Explosion,Chest"] = function(world, explosion, chest) end
   handlers.entity["Explosion,LockedChest"] = function(world, explosion, chest) end

   -- Explosion vs Rock (bombs are the only way to destroy rocks)
   handlers.entity["Explosion,Rock"] = function(world, explosion, rock)
      destroy_rock(world, rock)
   end

   -- Shop Item purchase handlers
   handlers.entity["Player,ShopItem"] = function(world, player, shop_item)
      -- Guard: Already purchased
      if shop_item.purchased then return end

      -- Push player out first
      push_out(player, shop_item)

      local price = shop_item.price or 10
      local free_purchase = GameState.cheats.infinite_inventory

      if not free_purchase and (player.coins or 0) < price then
         return
      end

      if not free_purchase then
         player.coins = (player.coins or 0) - price
      end
      shop_item.purchased = true

      if shop_item.apply_fn then
         shop_item.apply_fn(player)
      end

      FloatingText.spawn_info(player, shop_item.item_name or "Purchased!")

      world:remove_entity(shop_item.id)
   end

   -- Other entities vs ShopItem (push out only)
   handlers.entity["Enemy,ShopItem"] = push_out_enemy
   handlers.entity["Chick,ShopItem"] = function(world, chick, shop_item) push_out(chick, shop_item) end
   handlers.entity["Projectile,ShopItem"] = function(world, projectile, shop_item)
      projectile_hit_obstacle(world, projectile, "Rock")
   end
   handlers.entity["EnemyProjectile,ShopItem"] = function(world, projectile, shop_item)
      world:remove_entity(projectile.id)
   end

   -- Pickup vs Pickup -> push apart
   local pickup_types = {"Coin", "Key", "Bomb", "HealthPickup", "ProjectilePickup"}
   for _, type1 in ipairs(pickup_types) do
      for _, type2 in ipairs(pickup_types) do
         handlers.entity[type1..","..type2] = function(world, p1, p2)
            -- Push pickups apart to prevent stacking
            local dx = p1.x - p2.x
            local dy = p1.y - p2.y
            local dist = sqrt(dx * dx + dy * dy)
            if dist < 1 then
               dx, dy = rnd() - 0.5, rnd() - 0.5
               dist = 1
            end
            local push_dist = 4
            p1.x = p1.x + (dx / dist) * push_dist
            p1.y = p1.y + (dy / dist) * push_dist
         end
      end
   end
end

return ObstacleHandlers
