-- Explosion entity factory (picobloc version)
-- Reusable explosion effect for bombs, enemy attacks, environmental hazards
local GameConstants = require("src/game/game_config")
local EntityUtils = require("src/utils/entity_utils")

local Explosion = {}

--- Spawn a single explosion at the given position
--- @param world ECSWorld - picobloc World
--- @param x number - Position x in pixels
--- @param y number - Position y in pixels
--- @param center_x number|nil - Optional center for knockback direction
--- @param center_y number|nil - Optional center for knockback direction
--- @return EntityID The spawned explosion entity ID
function Explosion.spawn(world, x, y, center_x, center_y)
   local config = GameConstants.Explosion

   -- Parse tags from config
   local tag_set = EntityUtils.parse_tags(config.tags)

   -- Build entity with centralized component builders
   local entity = {
      -- Type identifier
      type = {value = config.entity_type or "Explosion"},

      -- Transform
      position = {x = x, y = y},
      size = EntityUtils.build_size(config),

      -- Collision (for damaging entities)
      collidable = EntityUtils.build_collidable(config, {map_collidable = false}),

      -- Combat
      contact_damage = {
         damage = config.damage or 20,
      },

      -- Visuals
      drawable = EntityUtils.build_drawable(config, nil, 27),
   }

   -- Apply parsed tags
   EntityUtils.apply_tags(entity, tag_set)

   local id = world:add_entity(entity)
   return id
end

--- Spawn explosions in a 3x3 grid around a center position
--- @param world ECSWorld - picobloc World
--- @param center_x number - Center position x in pixels
--- @param center_y number - Center position y in pixels
--- @param radius number - Radius in tiles (1 = 3x3, 2 = 5x5, etc.)
function Explosion.spawn_grid(world, center_x, center_y, radius)
   radius = radius or 1

   for dy = -radius, radius do
      for dx = -radius, radius do
         local ex = center_x + dx * GRID_SIZE
         local ey = center_y + dy * GRID_SIZE
         Explosion.spawn(world, ex, ey, center_x, center_y)
      end
   end
end

return Explosion
