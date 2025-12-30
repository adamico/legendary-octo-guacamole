-- Obstacle collision handlers
-- Handles collisions with Rocks and Destructibles

local Entities = require("src/entities")
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

-- Helper: handle egg break on obstacle collision
-- Guards against being called multiple times for the same projectile
local function projectile_hit_obstacle(projectile)
   -- Prevent double processing if projectile hits multiple obstacles in same frame
   if projectile.hit_obstacle then return end
   projectile.hit_obstacle = true

   -- Use hitbox center for spawn position
   local hb = HitboxUtils.get_hitbox(projectile)
   local spawn_x = hb.x + hb.w / 2 - 8
   local spawn_y = hb.y + hb.h / 2 - 8
   local spawn_z = projectile.z

   -- Single roll with 3 equal outcomes (33% each)
   local roll = rnd()

   -- Get projectile stats
   local hatch_time = projectile.hatch_time or 120
   local drain_heal = projectile.drain_heal or 5

   if roll < 0.33 then
      -- Heavy Impact (33%): Egg breaks, sunk cost (Net: -5 HP)
      Effects.spawn_visual_effect(world, spawn_x, spawn_y, BROKEN_EGG_SPRITE, 15)
   elseif roll < 0.66 then
      -- The Hatching (33%): Spawns a chick (Net: -5 HP, +1 Minion)
      Entities.spawn_egg(world, spawn_x, spawn_y, {
         hatch_timer = hatch_time,
         z = spawn_z,
      })
   else
      -- Parasitic Drain (33%): Refund/Heal (Net: 0 HP - Free shot)
      -- Spawns a health pickup equal to the drain heal amount
      local ground_y = spawn_y + (spawn_z or 0)
      Entities.spawn_health_pickup(world, spawn_x, ground_y, drain_heal)
   end
   world.del(projectile)
end

-- Register all obstacle handlers
function ObstacleHandlers.register(handlers)
   -- Player/Enemy push-out
   handlers.entity["Player,Rock"] = function(player, rock) push_out(player, rock) end
   handlers.entity["Player,Destructible"] = function(player, dest) push_out(player, dest) end
   handlers.entity["Enemy,Rock"] = function(enemy, rock)
      if world.msk(enemy).flying then return end
      push_out(enemy, rock)
   end
   handlers.entity["Enemy,Destructible"] = function(enemy, dest)
      if world.msk(enemy).flying then return end
      push_out(enemy, dest)
   end

   -- Melee vs Destructible
   handlers.entity["MeleeHitbox,Destructible"] = function(hitbox, destructible)
      destroy_destructible(destructible, hitbox.owner_entity)
   end

   -- Projectile vs Rock
   handlers.entity["Projectile,Rock"] = function(projectile, rock)
      projectile_hit_obstacle(projectile)
   end

   -- Projectile vs Destructible
   handlers.entity["Projectile,Destructible"] = function(projectile, destructible)
      destroy_destructible(destructible, projectile)
      projectile_hit_obstacle(projectile)
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

   -- Explosion vs Destructible (bombs destroy destructibles)
   handlers.entity["Explosion,Destructible"] = function(explosion, destructible)
      destroy_destructible(destructible, explosion)
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
