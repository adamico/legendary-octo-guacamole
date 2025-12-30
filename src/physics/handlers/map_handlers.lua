-- Map collision handlers
-- Handles entity collisions with the tile map (walls)

local Entities = require("src/entities")
local HitboxUtils = require("src/utils/hitbox_utils")
local GameConstants = require("src/game/game_config")
local Effects = require("src/systems/effects")

local MapHandlers = {}

-- Register all map handlers
function MapHandlers.register(handlers)
   handlers.map["Projectile"] = function(projectile)
      -- Prevent double processing if already handled by entity collision
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

   handlers.map["EnemyProjectile"] = function(projectile)
      world.del(projectile)
   end

   handlers.map["Enemy"] = function(enemy)
      enemy.hit_wall = true
      if enemy.enemy_type == "Dasher" and enemy.dasher_fsm and enemy.dasher_fsm:is("dash") then
         enemy.dasher_collision = true
      end
   end

   handlers.map["Chick"] = function(minion)
      minion.hit_wall = true
   end
end

return MapHandlers
