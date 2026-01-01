-- Explosion entity factory (picobloc version)
-- Reusable explosion effect for bombs, enemy attacks, environmental hazards
local GameConstants = require("src/game/game_config")

local Explosion = {}

-- Spawn a single explosion at the given position
--- @param world World - picobloc World
--- @param x number - Position x in pixels
--- @param y number - Position y in pixels
--- @param center_x number|nil - Optional center for knockback direction
--- @param center_y number|nil - Optional center for knockback direction
--- @return number The spawned explosion entity ID
function Explosion.spawn(world, x, y, center_x, center_y)
   local config = GameConstants.Explosion

   -- Parse tags from comma-separated config string
   local tag_set = {}
   for tag in all(split(config.tags or "", ",")) do
      tag_set[tag] = true
   end

   -- Build entity with components
   local entity = {
      -- Type identifier
      type = {value = config.entity_type or "Explosion"},

      -- Transform
      position = {x = x, y = y},
      size = {width = config.width or 16, height = config.height or 16},

      -- Collision (for damaging entities)
      collidable = {
         hitboxes = {
            w = config.hitbox_width or 16,
            h = config.hitbox_height or 16,
            ox = config.hitbox_offset_x or 0,
            oy = config.hitbox_offset_y or 0,
         },
         map_collidable = false,
      },

      -- Combat
      contact_damage = {
         damage = config.damage or 20,
      },

      -- Visuals: Drawable
      drawable = {
         outline_color = nil,
         sort_offset_y = 0,
         sprite_index = config.sprite_index or 27,
         flip_x = false,
         flip_y = false,
      },
   }

   -- Copy all parsed tags into entity
   for tag, _ in pairs(tag_set) do
      entity[tag] = true
   end

   local id = world:add_entity(entity)
   return id
end

-- Spawn explosions in a 3x3 grid around a center position
--- @param world World - picobloc World
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
