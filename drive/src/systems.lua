-- Systems module: reusable ECS system functions
local Systems = {}

-- Spotlight color constants
-- Color 32 = shadow effect (darkens underlying colors)
-- Color 33 = spotlight effect (brightens underlying colors)
local SPOTLIGHT_COLOR = 33
local SHADOW_COLOR = 32

local spotlight_initialized = false

-- Initialize the extended palette (colors 32-63)
-- Defines lighter/darker variants for base colors 0-15
-- Uses the 50% formula from the user reference
function Systems.init_extended_palette()
   local base_colors = {
      [0] = 0x000000,
      [1] = 0x1d2b53,
      [2] = 0x7e2553,
      [3] = 0x008751,
      [4] = 0xab5236,
      [5] = 0x5f574f,
      [6] = 0xc2c3c7,
      [7] = 0xfff1e8,
      [8] = 0xff004d,
      [9] = 0xffa300,
      [10] = 0xffec27,
      [11] = 0x00e436,
      [12] = 0x29adff,
      [13] = 0x83769c,
      [14] = 0xff77a8,
      [15] = 0xffccaa
   }

   for i = 0, 15 do
      local c = base_colors[i]
      local r = (c >> 16) & 0xff
      local g = (c >> 8) & 0xff
      local b = c & 0xff

      -- Lighter variant (50% toward white)
      local lr = flr(r + (255 - r) * 0.02)
      local lg = flr(g + (255 - g) * 0.02)
      local lb = flr(b + (255 - b) * 0.02)
      local light_argb = 0xff000000 | (lr << 16) | (lg << 8) | lb
      pal(32 + i, light_argb, 2)

      -- Darker variant (50% toward black)
      local dr = flr(r * 0.5)
      local dg = flr(g * 0.5)
      local db = flr(b * 0.5)
      local dark_argb = 0xff000000 | (dr << 16) | (dg << 8) | db
      pal(48 + i, dark_argb, 2)
   end
end

-- Initialize the spotlight color table
-- This modifies the default color table at 0x8000 to add spotlight/shadow effects
-- Row 33 (spotlight): maps colors to their lighter variants
-- Row 32 (shadow): maps colors to their darker variants
function Systems.init_spotlight()
   if spotlight_initialized then return end

   local spotlight_row_address = 0x8000 + SPOTLIGHT_COLOR * 64
   local shadow_row_address = 0x8000 + SHADOW_COLOR * 64

   for target_col = 0, 63 do
      local bright_col, dark_col

      -- Default is identity (no change)
      bright_col = target_col
      dark_col = target_col

      if target_col <= 15 then
         -- Base colors: map to variants
         bright_col = 32 + target_col
         dark_col = 48 + target_col
      elseif target_col >= 32 and target_col <= 47 then
         -- Spotlighted colors: shadow should make them DARKER, not just normal base colors
         local base = target_col - 32
         dark_col = 48 + base -- Shadow makes it the dark variant even if lit
      elseif target_col >= 48 and target_col <= 63 then
         -- Shadowed colors: spotlight should turn them back to base colors
         local base = target_col - 48
         bright_col = base -- Spotlight cancels shadow
      end

      poke(spotlight_row_address + target_col, bright_col)
      poke(shadow_row_address + target_col, dark_col)
   end

   -- Enable color table lookup for shapes (circfill, rectfill, etc.)
   poke(0x550b, 0x3f)

   spotlight_initialized = true
end

-- Input system: read controls and set direction
function Systems.controllable(entity)
   local left = btn(GameConstants.controls.move_left)
   local right = btn(GameConstants.controls.move_right)
   local up = btn(GameConstants.controls.move_up)
   local down = btn(GameConstants.controls.move_down)

   entity.dir_x = 0
   entity.dir_y = 0

   if left then entity.dir_x = -1 end
   if right then entity.dir_x = 1 end
   if up then entity.dir_y = -1 end
   if down then entity.dir_y = 1 end
end

function Systems.change_sprite(entity)
   local dx = entity.dir_x or 0
   local dy = entity.dir_y or 0
   local neutral = (dx == 0 and dy == 0)
   local down = (dx == 0 and dy == 1)
   local down_right = (dx == 1 and dy == 1)
   local down_left = (dx == -1 and dy == 1)
   local right = (dx == 1 and dy == 0)
   local up_right = (dx == 1 and dy == -1)
   local up = (dx == 0 and dy == -1)
   local up_left = (dx == -1 and dy == -1)
   local left = (dx == -1 and dy == 0)
   local sprite_index
   local flip = false
   if neutral or down then sprite_index = GameConstants.Player.sprite_index_offsets.down end
   if right or down_right or up_right then sprite_index = GameConstants.Player.sprite_index_offsets.right end
   if up or up_left or down_left then sprite_index = GameConstants.Player.sprite_index_offsets.up end
   if left or up_left or down_left then
      sprite_index = GameConstants.Player.sprite_index_offsets.right
      flip = true
   end

   entity.sprite_index = sprite_index
   entity.flip = flip
end

-- Physics systems
-- Acceleration system: apply acceleration, friction, and clamp velocity
function Systems.acceleration(entity)
   local dx = entity.dir_x or 0
   local dy = entity.dir_y or 0

   -- Normalize acceleration for diagonal movement
   local accel = entity.accel
   if dx ~= 0 and dy ~= 0 then
      accel *= 0.7071
   end

   -- Apply acceleration
   entity.vel_x += dx * accel
   entity.vel_y += dy * accel

   -- Apply friction when no input on that axis
   if dx == 0 then entity.vel_x *= entity.friction end
   if dy == 0 then entity.vel_y *= entity.friction end

   -- Clamp to max speed
   local max_spd = entity.max_speed
   entity.vel_x = mid(-max_spd, entity.vel_x, max_spd)
   entity.vel_y = mid(-max_spd, entity.vel_y, max_spd)

   -- Stop completely if very slow (prevents drift)
   if abs(entity.vel_x) < 0.1 then entity.vel_x = 0 end
   if abs(entity.vel_y) < 0.1 then entity.vel_y = 0 end
end

-- Velocity system: apply velocity to position with sub-pixel precision
function Systems.velocity(entity)
   -- Initialize sub-pixel accumulators if not present
   entity.sub_x = entity.sub_x or 0
   entity.sub_y = entity.sub_y or 0

   -- Accumulate velocity (including fractional parts)
   entity.sub_x += entity.vel_x
   entity.sub_y += entity.vel_y

   -- Extract whole pixel movement
   local move_x = flr(entity.sub_x)
   local move_y = flr(entity.sub_y)

   -- Handle negative values correctly (flr rounds toward negative infinity)
   if entity.sub_x < 0 and entity.sub_x ~= move_x then
      move_x = ceil(entity.sub_x) - 1
   end
   if entity.sub_y < 0 and entity.sub_y ~= move_y then
      move_y = ceil(entity.sub_y) - 1
   end

   -- Apply whole pixel movement
   entity.x += move_x
   entity.y += move_y

   -- Keep the remainder for next frame
   entity.sub_x -= move_x
   entity.sub_y -= move_y
end

-- Helper: Check if a rectangular area overlaps any solid map tiles
local function is_solid(x, y, w, h)
   local x1 = flr(x / GRID_SIZE)
   local y1 = flr(y / GRID_SIZE)
   local x2 = flr((x + w - 0.001) / GRID_SIZE)
   local y2 = flr((y + h - 0.001) / GRID_SIZE)

   for tx = x1, x2 do
      for ty = y1, y2 do
         if fget(mget(tx, ty), SOLID_FLAG) then
            return true
         end
      end
   end
   return false
end

-- Map collision system: check for collisions with the map tiles
function Systems.map_collision(entity)
   local x = entity.x
   local y = entity.y
   local w = entity.width or 16
   local h = entity.height or 16
   local sub_x = entity.sub_x or 0
   local sub_y = entity.sub_y or 0

   -- X collision: predict movement
   local move_x = flr(sub_x + entity.vel_x)
   if sub_x + entity.vel_x < 0 and sub_x + entity.vel_x ~= move_x then
      move_x = ceil(sub_x + entity.vel_x) - 1
   end

   if is_solid(x + move_x, y, w, h) then
      entity.vel_x = 0
      entity.sub_x = 0
   end

   -- Y collision: predict movement (using potentially updated sub_x/vel_x)
   local move_y = flr(sub_y + entity.vel_y)
   if sub_y + entity.vel_y < 0 and sub_y + entity.vel_y ~= move_y then
      move_y = ceil(sub_y + entity.vel_y) - 1
   end

   if is_solid(x + (entity.sub_x == 0 and 0 or move_x), y + move_y, w, h) then
      entity.vel_y = 0
      entity.sub_y = 0
   end
end

-- Drawing systems
-- Drawable system: render entity sprite with animation
function Systems.drawable(entity)
   spr(t() * 30 % 30 < 15 and entity.sprite_index or entity.sprite_index + 1, entity.x, entity.y, entity.flip)
end

function Systems.draw_shadow(entity, clip_square)
   local x1, y1 = entity.x + 1, entity.y + 11
   local x2, y2 = entity.x + entity.width - 2, y1 + 6
   clip(clip_square.x, clip_square.y, clip_square.w, clip_square.h)
   ovalfill(x1, y1, x2, y2, SHADOW_COLOR)
   clip()
end

-- Spotlight system: draws a circular spotlight around the entity
-- Uses color 33 which is mapped in the color table to brighten underlying colors
function Systems.draw_spotlight(entity, clip_square)
   -- Calculate spotlight center (centered on entity)
   local center_x = entity.x + (entity.width or 16) / 2
   local center_y = entity.y + (entity.height or 16) / 2

   -- Spotlight parameters (can be customized per entity)
   local radius = entity.spotlight_radius or 48

   -- Draw the spotlight circle using color 33 (spotlight effect)
   -- The color table maps color 33 to brighten whatever is underneath
   clip(clip_square.x, clip_square.y, clip_square.w, clip_square.h)
   circfill(center_x, center_y, radius, SPOTLIGHT_COLOR)
   clip()
end

return Systems
