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

      -- Use hitbox center to check what we hit
      local hb = HitboxUtils.get_hitbox(projectile)
      local cx = hb.x + hb.w / 2
      local cy = hb.y + hb.h / 2

      -- Helper to get tile under center
      local tx = flr(cx / 16) -- GRID_SIZE
      local ty = flr(cy / 16)
      local tile = mget(tx, ty) or 0

      -- Check for Pit (Silent sink)
      -- Need GameConstants.PIT_TILE or check flag?
      -- Using flag is safer if defined, but specific tile 85 is in tiles.lua
      -- Let's check both or use helper. Collision.is_pit?
      -- Collision module not required here, but we can check flag.
      -- FEATURE_FLAG_PIT = 1 in tiles.lua
      if fget(tile, 1) then -- FEATURE_FLAG_PIT
         -- Silent delete (sinking)
         world.del(projectile)
         return
      end

      -- Spawn Yolk Splat at wall base (visual + slow + edible)
      local spawn_x = cx - 8
      local spawn_y = cy - 8

      -- Using Utils to spawn so tags/shadows are processed if needed
      Entities.spawn_entity(world, GameConstants.EntityCollisionLayer.WORLD, {
         x = spawn_x,
         y = spawn_y,
         width = 16,
         height = 16,
         type = "YolkSplat", -- Must match config key
         hitbox_width = 12,
         hitbox_height = 12,
         creation_time = t(),
         lifespan = GameConstants.Player.yolk_splat_duration or 300,
         yolk_slow_factor = GameConstants.Player.yolk_slow_factor or 0.7,
      }, "YolkSplat")

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
