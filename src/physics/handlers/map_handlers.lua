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

      -- Use hitbox center to check what we hit
      local hb = HitboxUtils.get_hitbox(projectile)
      local cx = hb.x + hb.w / 2
      local cy = hb.y + hb.h / 2

      -- Helper to get tile under center
      local tx = flr(cx / GRID_SIZE)
      local ty = flr(cy / GRID_SIZE)
      local tile = mget(tx, ty) or 0

      -- Check for Pit (Silent sink)
      if fget(tile, FEATURE_FLAG_PIT) then
         world:remove_entity(projectile.id)
         return
      end

      -- Spawn Yolk Splat at wall base (visual + slow + edible)
      local spawn_x = cx - GRID_SIZE / 2
      local spawn_y = cy - GRID_SIZE / 2

      -- Using Entities convenience helper for YolkSplat
      Entities.spawn_yolk_splat(world, spawn_x, spawn_y, {
         creation_time = t(),
         lifespan = GameConstants.Player.yolk_splat_duration,
         yolk_slow_factor = GameConstants.Player.yolk_slow_factor,
      })

      world:remove_entity(projectile.id)
   end

   handlers.map["EnemyProjectile"] = function(projectile)
      world:remove_entity(projectile.id)
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
