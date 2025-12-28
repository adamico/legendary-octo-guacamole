-- Explosion entity factory
-- Reusable explosion effect for bombs, enemy attacks, environmental hazards, etc.

local GameConstants = require("src/game/game_config")
local EntityUtils = require("src/utils/entity_utils")

local Explosion = {}

-- Spawn a single explosion at the given position
-- @param world - ECS world
-- @param x, y - Position in pixels
-- @param center_x, center_y - Optional center for knockback direction (defaults to x, y)
-- @return The spawned explosion entity
function Explosion.spawn(world, x, y, center_x, center_y)
   local config = GameConstants.Explosion

   local entity = {
      type = config.entity_type,
      x = x,
      y = y,
      width = config.width,
      height = config.height,
      sprite_index = config.sprite_index,
      lifespan = config.lifespan,
      hitbox_width = config.hitbox_width,
      hitbox_height = config.hitbox_height,
      hitbox_offset_x = config.hitbox_offset_x,
      hitbox_offset_y = config.hitbox_offset_y,
      -- Store explosion center for radial knockback
      explosion_center_x = center_x or x,
      explosion_center_y = center_y or y,
      explosion_damage = config.damage or 20,
   }

   return EntityUtils.spawn_entity(world, config.tags, entity)
end

-- Spawn explosions in a 3x3 grid around a center position
-- @param world - ECS world
-- @param center_x, center_y - Center position in pixels (typically bomb position)
-- @param radius - Radius in tiles (1 = 3x3, 2 = 5x5, etc.)
function Explosion.spawn_grid(world, center_x, center_y, radius)
   radius = radius or 1

   for dy = -radius, radius do
      for dx = -radius, radius do
         local ex = center_x + dx * GRID_SIZE
         local ey = center_y + dy * GRID_SIZE
         -- Pass the bomb center so all explosions knockback from center
         Explosion.spawn(world, ex, ey, center_x, center_y)
      end
   end
end

return Explosion
