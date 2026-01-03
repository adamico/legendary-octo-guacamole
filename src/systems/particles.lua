-- Particle System using Picotron batch GFX operations
-- Uses userdata pools for efficient CPU usage

local Particles = {}

-- Configuration
local MAX_PARTICLES = 256
local GRAVITY = 0.15
local FRICTION = 0.98

-- Particle pool (columns: x, y, vx, vy, life, color, size)
local pool = nil
local draw_buf = nil

-- Particle type presets
local PRESETS = {
   hit_spark = {
      count = 5,
      speed_min = 1.5,
      speed_max = 3.0,
      life_min = 8,
      life_max = 15,
      size_min = 1,
      size_max = 2,
      colors = {7, 10, 9, 25}, -- white, yellow, orange, dark orange
      gravity = 0,
      friction = 0.9,
   },
   yolk = {
      count = 8,
      speed_min = 0.8,
      speed_max = 2,
      life_min = 15,
      life_max = 30,
      size_min = 1,
      size_max = 2,
      colors = {9, 25}, -- dark orange
      gravity = 0,
      friction = 1,
   },
   explosion = {
      count = 50,
      speed_min = 2.0,
      speed_max = 4,
      life_min = 15,
      life_max = 30,
      size_min = 2,
      size_max = 4,
      colors = {10, 9, 25, 24}, -- yellow, orange, dark orange, dark red
      gravity = 0.05,
      friction = 0.95,
   },
   blood = {
      count = 6,
      speed_min = 0.5,
      speed_max = 2.0,
      life_min = 20,
      life_max = 40,
      size_min = 1,
      size_max = 3,
      colors = {8, 2, 1}, -- red, dark red, dark blue
      gravity = 0.2,
      friction = 0.98,
   },
   smoke = {
      count = 4,
      speed_min = 0.2,
      speed_max = 0.5,
      life_min = 30,
      life_max = 60,
      size_min = 2,
      size_max = 4,
      colors = {6, 5, 1}, -- gray, dark gray, dark blue
      gravity = -0.02,    -- rises
      friction = 0.99,
   },
   sparkle = {
      count = 8,
      speed_min = 0.3,
      speed_max = 1.0,
      life_min = 10,
      life_max = 25,
      size_min = 1,
      size_max = 1,
      colors = {7, 10, 12, 11}, -- white, yellow, cyan, green
      gravity = 0,
      friction = 0.95,
   },
}

--- Initialize the particle system
function Particles.init()
   -- Create particle pool: x, y, vx, vy, life, color, size, gravity, friction
   pool = userdata("f64", 9, MAX_PARTICLES)
   -- Zero out pool (all particles dead)
   for i = 0, MAX_PARTICLES - 1 do
      pool:set(0, i, 0, 0, 0, 0, 0, 0, 0, 0, 0)
   end

   -- Create reusable draw buffer for circfill batch
   draw_buf = userdata("f64", 4, MAX_PARTICLES)
end

--- Find next free slot in pool
--- @return number|nil Free slot index or nil if pool is full
local function find_free_slot()
   for i = 0, MAX_PARTICLES - 1 do
      if pool:get(4, i) <= 0 then -- life column
         return i
      end
   end
   return nil
end

--- Spawn a single particle
--- @param x number X position
--- @param y number Y position
--- @param vx number X velocity
--- @param vy number Y velocity
--- @param life number Lifetime in frames
--- @param color number Draw color
--- @param size number Radius
--- @param gravity number|nil Gravity (default 0)
--- @param friction number|nil Friction (default 1)
function Particles.spawn(x, y, vx, vy, life, color, size, gravity, friction)
   local slot = find_free_slot()
   if not slot then return end

   pool:set(0, slot,
      x, y, vx, vy, life, color, size,
      gravity or 0,
      friction or 1
   )
end

--- Spawn a burst of particles with preset type
--- @param x number Center X
--- @param y number Center Y
--- @param ptype string Particle type ("hit_spark", "explosion", etc)
--- @param count number|nil Override count
function Particles.spawn_burst(x, y, ptype, count)
   local preset = PRESETS[ptype]
   if not preset then return end

   count = count or preset.count

   for i = 1, count do
      -- Random direction
      local angle = rnd(1) * 6.2832 -- 2*pi
      local speed = preset.speed_min + rnd(1) * (preset.speed_max - preset.speed_min)
      local vx = cos(angle / 6.2832) * speed
      local vy = sin(angle / 6.2832) * speed

      -- Random properties
      local life = preset.life_min + flr(rnd(1) * (preset.life_max - preset.life_min + 1))
      local color = preset.colors[flr(rnd(1) * #preset.colors) + 1]
      local size = preset.size_min + flr(rnd(1) * (preset.size_max - preset.size_min + 1))

      Particles.spawn(x, y, vx, vy, life, color, size, preset.gravity, preset.friction)
   end
end

--- Update all particles (physics + decay)
function Particles.update()
   if not pool then return end

   for i = 0, MAX_PARTICLES - 1 do
      local life = pool:get(4, i)
      if life > 0 then
         -- Get current values
         local x = pool:get(0, i)
         local y = pool:get(1, i)
         local vx = pool:get(2, i)
         local vy = pool:get(3, i)
         local gravity = pool:get(7, i)
         local friction = pool:get(8, i)

         -- Apply gravity
         vy = vy + gravity

         -- Apply friction
         vx = vx * friction
         vy = vy * friction

         -- Update position
         x = x + vx
         y = y + vy

         -- Decrement life
         life = life - 1

         -- Write back
         pool:set(0, i, x, y, vx, vy, life)
      end
   end
end

--- Draw all living particles using batch circfill
--- @param clip_bounds table|nil Optional clip bounds {x, y, w, h}
function Particles.draw(clip_bounds)
   if not pool or not draw_buf then return end

   -- Apply clipping if bounds provided
   if clip_bounds then
      clip(clip_bounds.x, clip_bounds.y, clip_bounds.w, clip_bounds.h)
   end

   local count = 0

   -- Extract living particles into draw buffer
   for i = 0, MAX_PARTICLES - 1 do
      local life = pool:get(4, i)
      if life > 0 then
         -- Copy x, y, size, color to draw buffer
         draw_buf:set(0, count,
            pool:get(0, i), -- x
            pool:get(1, i), -- y
            pool:get(6, i), -- size (radius)
            pool:get(5, i)  -- color
         )
         count = count + 1
      end
   end

   -- Batch draw all living particles
   if count > 0 then
      circfill(draw_buf, 0, count, 4, 4)
   end

   -- Reset clipping
   if clip_bounds then
      clip()
   end
end

--- Get current active particle count (for debugging)
--- @return number Active particle count
function Particles.get_count()
   if not pool then return 0 end
   local count = 0
   for i = 0, MAX_PARTICLES - 1 do
      if pool:get(4, i) > 0 then
         count = count + 1
      end
   end
   return count
end

return Particles
