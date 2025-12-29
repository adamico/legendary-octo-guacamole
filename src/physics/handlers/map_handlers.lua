-- Map collision handlers
-- Handles entity collisions with the tile map (walls)

local Entities = require("src/entities")
local HitboxUtils = require("src/utils/hitbox_utils")
local GameConstants = require("src/game/game_config")

local MapHandlers = {}

-- Register all map handlers
function MapHandlers.register(handlers)
   handlers.map["Projectile"] = function(projectile)
      -- Prevent double processing if already handled by entity collision
      if projectile.hit_obstacle then return end
      projectile.hit_obstacle = true

      local recovery = (projectile.shot_cost or 0) * (projectile.recovery_percent or 0)
      -- Use hitbox center for accurate spawn position
      -- Note: hitbox.y already accounts for z (visual elevation)
      local hb = HitboxUtils.get_hitbox(projectile)
      local pickup_config = GameConstants.Pickup.ProjectilePickup
      local half_pickup_w = (pickup_config.width or 16) / 2
      local half_pickup_h = (pickup_config.height or 16) / 2
      local spawn_x = hb.x + hb.w / 2 - half_pickup_w
      local spawn_y = hb.y + hb.h / 2 - half_pickup_h
      local spawn_z = projectile.z

      Entities.spawn_pickup_projectile(world, spawn_x, spawn_y, projectile.dir_x, projectile.dir_y, recovery,
         projectile.sprite_index, spawn_z, projectile.vertical_shot)
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
