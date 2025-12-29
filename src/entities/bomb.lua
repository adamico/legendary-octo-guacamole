-- Bomb entity factory
-- Handles spawning PlacedBomb entities (the timed explosive, not the pickup)

local GameConstants = require("src/game/game_config")
local EntityUtils = require("src/utils/entity_utils")

local Bomb = {}

-- Spawn a placed bomb at the given position
-- @param world - ECS world
-- @param x, y - Position in pixels (will be tile-aligned)
function Bomb.spawn(world, x, y)
   local config = GameConstants.PlacedBomb

   -- Tile-align the position (snap to 16x16 grid)
   local tile_x = flr(x / GRID_SIZE) * GRID_SIZE
   local tile_y = flr(y / GRID_SIZE) * GRID_SIZE

   local entity = {
      type = config.entity_type,
      x = tile_x,
      y = tile_y,
      width = config.width,
      height = config.height,
      sprite_index = config.sprite_index,
      fuse_timer = config.fuse_time,
      explosion_radius = config.explosion_radius,
      shadow_offset_y = config.shadow_offset_y,
      shadow_offset_x = config.shadow_offset_x or 0,
      shadow_width = config.shadow_width,
   }

   return EntityUtils.spawn_entity(world, config.tags, entity)
end

return Bomb
