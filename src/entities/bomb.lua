-- Bomb entity factory (picobloc version)
-- Handles spawning PlacedBomb entities (the timed explosive, not the pickup)
local GameConstants = require("src/game/game_config")

local Bomb = {}

-- Spawn a placed bomb at the given position
--- @param world World - picobloc World
--- @param x number - Position x in pixels (will be tile-aligned)
--- @param y number - Position y in pixels (will be tile-aligned)
function Bomb.spawn(world, x, y)
   local config = GameConstants.PlacedBomb

   -- Parse tags from comma-separated config string
   local tag_set = {}
   for tag in all(split(config.tags or "", ",")) do
      tag_set[tag] = true
   end

   -- Tile-align the position (snap to 16x16 grid)
   local tile_x = flr(x / GRID_SIZE) * GRID_SIZE
   local tile_y = flr(y / GRID_SIZE) * GRID_SIZE

   -- Build entity with components
   local entity = {
      -- Type identifier
      type = {value = config.entity_type or "PlacedBomb"},

      -- Transform
      position = {x = tile_x, y = tile_y},
      size = {width = config.width or 16, height = config.height or 16},

      -- Timers (fuse)
      timers = {
         shoot_cooldown = 0,
         invuln_timer = 0,
         hp_drain_timer = config.fuse_time or 180, -- Repurpose for fuse timer
      },

      -- Visuals: Shadow
      shadow = {
         shadow_offset_x = config.shadow_offset_x or 0,
         shadow_offset_y = config.shadow_offset_y or 0,
         shadow_width = config.shadow_width or 12,
         shadow_height = 3,
         shadow_offsets_x = nil,
         shadow_offsets_y = nil,
         shadow_widths = nil,
         shadow_heights = nil,
      },

      -- Visuals: Drawable
      drawable = {
         outline_color = nil,
         sort_offset_y = 0,
         sprite_index = config.sprite_index or 22,
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

return Bomb
