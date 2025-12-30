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

      -- Two-roll logic for non-living collision
      local integrity = projectile.integrity or 0
      local fertility = projectile.fertility or 0

      if rnd() < integrity then
         -- Egg survives intact: fertility roll
         if rnd() < fertility then
            -- Fertility success: spawn egg that will hatch into chick
            Entities.spawn_egg(world, spawn_x, spawn_y, {
               hatch_timer = projectile.hatch_time or 120,
               z = spawn_z,
            })
         else
            -- Fertility fail: spawn refund pickup
            local refund = projectile.shot_cost or 0
            Entities.spawn_pickup_projectile(world, spawn_x, spawn_y, projectile.dir_x, projectile.dir_y, refund,
               projectile.sprite_index, spawn_z, projectile.vertical_shot)
         end
      else
         -- Egg breaks: show broken egg effect and spawn health pickup at ground level (50% of shot cost)
         Effects.spawn_visual_effect(world, spawn_x, spawn_y, BROKEN_EGG_SPRITE, 15)
         local heal_amount = (projectile.shot_cost or 0) * 0.5
         local ground_y = spawn_y + (spawn_z or 0) -- Adjust Y to ground level
         Entities.spawn_health_pickup(world, spawn_x, ground_y, heal_amount)
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
