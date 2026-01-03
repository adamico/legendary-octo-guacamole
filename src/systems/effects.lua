-- Effects system: reusable visual, audio, and physical feedback
local Particles = require("src/systems/particles")

local Effects = {}
-- Screen shake state
local shake_timer = 0
local shake_intensity = 0

-- Sprite flash state (per entity)
-- entity.flash_timer and entity.flash_color set dynamically

-- Screen shake effect
function Effects.screen_shake(intensity, duration)
   shake_intensity = max(shake_intensity, intensity or 2)
   shake_timer = max(shake_timer, duration or 3)
end

-- Update shake (call from main game loop)
function Effects.update_shake()
   if shake_timer > 0 then
      shake_timer -= 1
      if shake_timer <= 0 then
         shake_intensity = 0
      end
   end
end

-- Get shake offset (call from draw loop, add to camera scroll)
function Effects.get_shake_offset()
   if shake_timer > 0 and shake_intensity > 0 then
      return {
         x = (rnd(2) - 1) * shake_intensity,
         y = (rnd(2) - 1) * shake_intensity
      }
   end
   return {x = 0, y = 0}
end

-- Flash sprite effect
function Effects.flash_sprite(entity, frames, color)
   entity.flash_timer = frames or 3
   entity.flash_color = color or 7 -- white by default
end

-- Update sprite flash (call from drawable system)
function Effects.update_flash(entity)
   if entity.flash_timer and entity.flash_timer > 0 then
      entity.flash_timer -= 1

      -- Solid flash for entire duration
      -- Swap all sprite colors to flash color using DRAW palette (Picotron has 64 colors)
      for i = 1, 63 do -- Skip 0 (transparent)
         pal(i, entity.flash_color or 7, 0)
      end
   end
   -- Note: Palette reset happens after sprite draw in play.lua
end

-- Spawn particle effect using batch particle system
function Effects.spawn_particles(x, y, ptype, count)
   Particles.spawn_burst(x, y, ptype, count)
end

--- Spawn a temporary visual effect sprite at position
---
--- @param world - ECS world
--- @param x, y - spawn position
--- @param sprite_index - sprite to display
--- @param lifespan - frames before removal (default 15)
function Effects.spawn_visual_effect(world, x, y, sprite_index, lifespan)
   lifespan = lifespan or 15
   local effect = {
      type = "VisualEffect",
      x = x,
      y = y,
      width = 16,
      height = 16,
      sprite_index = sprite_index,
      lifespan = lifespan,
   }
   world.ent("drawable,sprite,timers,middleground", effect)
end

-- Apply knockback to target entity, pushing away from source
-- Uses separate knockback velocity that decays with friction
function Effects.apply_knockback(source, target, strength)
   strength = strength or 3

   -- Calculate direction from source center to target center
   local src_cx = source.x + (source.width or 0) / 2
   local src_cy = source.y + (source.height or 0) / 2
   local tgt_cx = target.x + (target.width or 0) / 2
   local tgt_cy = target.y + (target.height or 0) / 2

   local dx = tgt_cx - src_cx
   local dy = tgt_cy - src_cy

   -- Normalize direction
   local len = sqrt(dx * dx + dy * dy)
   if len > 0 then
      dx = dx / len
      dy = dy / len
   else
      -- Default push if overlapping exactly
      dx = 0
      dy = -1
   end

   -- Set knockback velocity (separate from movement velocity)
   -- This will be processed and decayed in the physics system
   target.knockback_vel_x = dx * strength
   target.knockback_vel_y = dy * strength
end

--- Apply stun and slow debuff to target entity ("Sticky Yolk" effect)
---
--- @param target Entity to debuff (must have velocity for movement)
--- @param stun_frames Frames of complete movement stop (~0.2s = 12)
--- @param slow_frames Frames of reduced speed (~1s = 60)
--- @param slow_factor Speed multiplier during slow (0.5 = 50% speed)
function Effects.apply_sticky_yolk(target, stun_frames, slow_frames, slow_factor)
   target.stun_timer = stun_frames or 12
   target.slow_timer = slow_frames or 60
   target.slow_factor = slow_factor or 0.5
end

-- Generic hit impact effect (reusable)
function Effects.hit_impact(source, target, intensity)
   intensity = intensity or "normal"

   -- Calculate impact point
   local px = (source.x + target.x) / 2
   local py = (source.y + target.y) / 2

   -- Visual effects
   Effects.spawn_particles(px, py, "hit_spark", 5)
   Effects.flash_sprite(target, 10, 7) -- 10 frames = ~166ms at 60fps

   -- Audio (context-based)
   if target.type == "Player" then
      -- sfx(2) -- pain sound (uncomment when SFX ready)
   elseif target.type == "Enemy" then
      -- sfx(5) -- hit sound (uncomment when SFX ready)
   end

   -- Screen shake (intensity-based)
   if intensity == "light_shake" then
      Effects.screen_shake(1, 2)
   elseif intensity == "normal_shake" then
      Effects.screen_shake(2, 3)
   elseif intensity == "heavy_shake" then
      Effects.screen_shake(4, 5)
   end
   -- "no_shake" or nil = no screen shake
end

-- Death explosion effect (reusable for enemy/player death)
function Effects.death_explosion(entity, ptype)
   ptype = ptype or "explosion"

   -- Bigger particle burst
   Effects.spawn_particles(entity.x + entity.width / 2, entity.y + entity.height / 2, ptype, 15)

   -- Flash before deletion
   Effects.flash_sprite(entity, 5, 7)

   -- Sound
   -- sfx(10) -- explosion sound (uncomment when SFX ready)
end

-- Pickup/collect effect
function Effects.pickup_collect(entity)
   Effects.spawn_particles(entity.x, entity.y, "sparkle", 8)
   -- sfx(6) -- pickup sound (uncomment when SFX ready)
end

-- Item Rise Animation (Zelda-style)
-- 1. Spawns item above origin
-- 2. Item rises slowly
-- 3. Floating text appears
-- 4. Item converts to normal pickup
function Effects.spawn_item_rise(world, x, y, sprite_index, item_name, on_finish_fn)
   local anim = {
      type = "ItemRiseAnim",
      x = x,
      y = y,
      y_start = y,
      width = 32,
      height = 32,
      sprite_index = sprite_index,
      rise_timer = 0,
      rise_duration = 60,
      item_name = item_name,
      on_finish = on_finish_fn,

      -- Drawing layer
      layer = "middleground",
   }
   world.ent("drawable,sprite,timers,middleground,item_rise_anim", anim)
end

-- Update item rise animations
function Effects.update_animations(world)
   world.sys("item_rise_anim", function(e)
      e.rise_timer += 1

      -- Slow rise (ease out?)
      -- Simple linear for now: 16 pixels up over 30 frames -> ~0.5 px/frame
      e.y -= 0.5

      if e.rise_timer >= e.rise_duration then
         if e.on_finish then
            e.on_finish(e)
         end

         -- Remove animation entity
         world.del(e)
      end
   end)()
end

return Effects
