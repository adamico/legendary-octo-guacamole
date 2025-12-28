-- Obstacle collision handlers
-- Handles collisions with Rocks and Destructibles

local Entities = require("src/entities")
local HitboxUtils = require("src/utils/hitbox_utils")

local ObstacleHandlers = {}

-- Loot table for destructibles (weights must sum to 1.0)
local DESTRUCTIBLE_LOOT = {
   {type = "Coin",         weight = 0.50},
   {type = "Bomb",         weight = 0.30},
   {type = "Key",          weight = 0.15},
   {type = "HealthPickup", weight = 0.05},
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
local function push_out(entity, obstacle)
   local e_hb = HitboxUtils.get_hitbox(entity)
   local o_hb = HitboxUtils.get_hitbox(obstacle)

   -- Calculate overlap on each axis
   local overlap_left = (e_hb.x + e_hb.w) - o_hb.x
   local overlap_right = (o_hb.x + o_hb.w) - e_hb.x
   local overlap_top = (e_hb.y + e_hb.h) - o_hb.y
   local overlap_bottom = (o_hb.y + o_hb.h) - e_hb.y

   -- Find minimum penetration axis
   local min_overlap = overlap_left
   local push_x, push_y = -overlap_left, 0

   if overlap_right < min_overlap then
      min_overlap = overlap_right
      push_x, push_y = overlap_right, 0
   end
   if overlap_top < min_overlap then
      min_overlap = overlap_top
      push_x, push_y = 0, -overlap_top
   end
   if overlap_bottom < min_overlap then
      min_overlap = overlap_bottom
      push_x, push_y = 0, overlap_bottom
   end

   -- Apply push to entity position
   entity.x = entity.x + push_x
   entity.y = entity.y + push_y

   -- Zero velocity in push direction to prevent jittering
   if push_x ~= 0 then entity.vel_x = 0 end
   if push_y ~= 0 then entity.vel_y = 0 end
end

-- Helper: spawn projectile pickup and delete projectile
local function projectile_hit_obstacle(projectile)
   local recovery = (projectile.shot_cost or 0) * (projectile.recovery_percent or 0)
   if recovery > 0 then
      Entities.spawn_pickup_projectile(world, projectile.x, projectile.y,
         projectile.dir_x, projectile.dir_y, recovery, projectile.sprite_index, projectile.z)
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
