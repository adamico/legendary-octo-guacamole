-- Bomb entity factory (picobloc version)
-- Handles spawning PlacedBomb entities (the timed explosive, not the pickup)
local GameConstants = require("src/game/game_config")
local EntityUtils = require("src/utils/entity_utils")

local Bomb = {}

--- Spawn a placed bomb at the given position
--- @param world ECSWorld - picobloc World
--- @param x number - Position x in pixels (will be tile-aligned)
--- @param y number - Position y in pixels (will be tile-aligned)
function Bomb.spawn(world, x, y)
   local config = GameConstants.PlacedBomb

   -- Parse tags from config
   local tag_set = EntityUtils.parse_tags(config.tags)

   -- Tile-align the position (snap to 16x16 grid)
   local tile_x = flr(x / GRID_SIZE) * GRID_SIZE
   local tile_y = flr(y / GRID_SIZE) * GRID_SIZE

   -- Build entity with centralized component builders
   local entity = {
      -- Type identifier
      type = {value = config.entity_type or "PlacedBomb"},

      -- Transform
      position = {x = tile_x, y = tile_y},
      size = EntityUtils.build_size(config),

      -- Timers (fuse)
      timers = EntityUtils.build_timers({
         hp_drain_timer = config.fuse_time or 180 -- Repurpose for fuse timer
      }),

      -- Visuals
      shadow = EntityUtils.build_shadow(config),
      drawable = EntityUtils.build_drawable(config, nil, 22),
   }

   -- Apply parsed tags
   EntityUtils.apply_tags(entity, tag_set)

   local id = world:add_entity(entity)
   return id
end

return Bomb
