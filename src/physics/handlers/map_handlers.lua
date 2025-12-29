-- Map collision handlers
-- Handles entity collisions with the tile map (walls)

local Entities = require("src/entities")

local MapHandlers = {}

-- Register all map handlers
function MapHandlers.register(handlers)
   -- Player projectile hitting wall -> spawn pickup
   handlers.map["Projectile"] = function(projectile, map_x, map_y, tx, ty, tile, room)
      local recovery = (projectile.shot_cost or 0) * (projectile.recovery_percent or 0)
      Entities.spawn_pickup_projectile(world, projectile.x, projectile.y, projectile.dir_x, projectile.dir_y, recovery,
         projectile.sprite_index, projectile.z)
      world.del(projectile)
   end

   -- Enemy projectile hitting wall -> just delete
   handlers.map["EnemyProjectile"] = function(projectile, map_x, map_y, tx, ty, tile, room)
      world.del(projectile)
   end

   -- Enemy hitting wall -> set flag for AI
   handlers.map["Enemy"] = function(enemy, map_x, map_y)
      enemy.hit_wall = true
      if enemy.enemy_type == "Dasher" and enemy.dasher_fsm and enemy.dasher_fsm:is("dash") then
         enemy.dasher_collision = true
      end
   end

   -- Minion (Chick) hitting wall -> set flag for Wander AI
   handlers.map["Chick"] = function(minion, map_x, map_y)
      minion.hit_wall = true
   end
end

return MapHandlers
