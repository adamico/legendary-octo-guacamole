-- Obstacle collision handlers
-- Handles collisions with Rocks and Destructibles

local Entities = require("src/entities")
local GameConstants = require("src/game/game_config")
local HitboxUtils = require("src/utils/hitbox_utils")
local Effects = require("src/systems/effects")

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

-- Helper: Open a chest entity and spawn loot
-- @param chest The chest entity
-- @param player The player entity (for key checking on locked chests)
-- @return true if chest was opened, false if locked and no key
local function open_chest(chest, player)
   if chest.dead or chest.opened then return false end

   -- Check if locked and player has keys
   if chest.is_locked then
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

   -- Spawn pickups in a spray pattern
   for i = 1, loot_count do
      local loot_type = pick_loot(CHEST_LOOT)
      -- Spread pickups in a circle pattern with some randomness
      local angle = (i / loot_count) * 6.28 + rnd(0.5) - 0.25
      local dist = 12 + rnd(8)
      local spawn_x = cx + cos(angle) * dist - 8
      local spawn_y = cy + sin(angle) * dist - 8
      Entities.spawn_pickup(world, spawn_x, spawn_y, loot_type)
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


-- Push entity out of obstacle (AABB minimum penetration resolution)
-- Respects solid tiles - won't push entity into walls
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

-- Push enemy out of obstacle and handle Dasher stun
local function push_out_enemy(enemy, obstacle)
   if world.msk(enemy).flying then return end
   push_out(enemy, obstacle)

   -- Special case: Dasher stunning on obstacle collision
   if enemy.enemy_type == "Dasher" and enemy.dasher_fsm and enemy.dasher_fsm:is("dash") then
      enemy.dasher_collision = true
   end
end

-- Helper: handle egg break on obstacle collision
-- Guards against being called multiple times for the same projectile
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

-- Register all obstacle handlers
function ObstacleHandlers.register(handlers)
   -- Player/Enemy push-out
   handlers.entity["Player,Rock"] = function(player, rock) push_out(player, rock) end
   handlers.entity["Player,Destructible"] = function(player, dest) push_out(player, dest) end
   handlers.entity["Enemy,Rock"] = push_out_enemy
   handlers.entity["Enemy,Destructible"] = push_out_enemy

   -- Chick (Minions) vs Obstacles
   handlers.entity["Chick,Rock"] = function(chick, rock) push_out(chick, rock) end
   handlers.entity["Chick,Destructible"] = function(chick, dest) push_out(chick, dest) end

   -- Player vs Chests (touching opens them)
   handlers.entity["Player,Chest"] = function(player, chest)
      push_out(player, chest)
      open_chest(chest, player)
   end
   handlers.entity["Player,LockedChest"] = function(player, chest)
      push_out(player, chest)
      open_chest(chest, player)
   end

   -- Chick vs Chests (push out only, can't open)
   handlers.entity["Chick,Chest"] = function(chick, chest) push_out(chick, chest) end
   handlers.entity["Chick,LockedChest"] = function(chick, chest) push_out(chick, chest) end

   -- Enemy vs Chests (push out only)
   handlers.entity["Enemy,Chest"] = push_out_enemy
   handlers.entity["Enemy,LockedChest"] = push_out_enemy

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

   -- Explosion vs Chest (bombs can open chests)
   handlers.entity["Explosion,Chest"] = function(explosion, chest)
      local player = nil
      world.sys("player", function(p) player = p end)()
      if player then
         open_chest(chest, player)
      end
   end
   handlers.entity["Explosion,LockedChest"] = function(explosion, chest)
      local player = nil
      world.sys("player", function(p) player = p end)()
      if player then
         open_chest(chest, player) -- Still requires key
      end
   end

   -- Explosion vs Rock (bombs are the only way to destroy rocks)
   handlers.entity["Explosion,Rock"] = function(explosion, rock)
      destroy_rock(rock)
   end

   -- Pickup vs Pickup -> push apart to prevent stacking
   local pickup_types = {"Coin", "Key", "Bomb", "HealthPickup", "ProjectilePickup"}
   for _, type1 in ipairs(pickup_types) do
      for _, type2 in ipairs(pickup_types) do
         handlers.entity[type1..","..type2] = function(p1, p2)
            -- Simple push: move p1 away from p2
            local dx = p1.x - p2.x
            local dy = p1.y - p2.y
            local dist = sqrt(dx * dx + dy * dy)
            if dist < 1 then
               dx, dy = rnd() - 0.5, rnd() - 0.5
               dist = 1
            end
            local push_dist = 2
            p1.x = p1.x + (dx / dist) * push_dist
            p1.y = p1.y + (dy / dist) * push_dist
         end
      end
   end
end

return ObstacleHandlers
