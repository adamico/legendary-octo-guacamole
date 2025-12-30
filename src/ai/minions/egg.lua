-- Egg AI behavior (hatching into a chick)
local Entities = require("src/entities")
local GameConstants = require("src/game/game_config")

return function(entity, world)
   -- Apply gravity while falling (z > 0)
   if entity.z and entity.z > 0 then
      entity.vel_z = (entity.vel_z or 0) + (entity.gravity_z or -0.15)
      entity.z = entity.z + entity.vel_z
      if entity.z <= 0 then
         entity.z = 0
         entity.vel_z = 0
         entity.landed = true
      end
      return -- Don't hatch while falling
   end

   -- Initialize hatch_time_max on first frame after landing
   if not entity.hatch_time_max then
      entity.hatch_time_max = entity.hatch_timer or 120
   end

   -- Update sprite based on hatch progress
   local hatch_frames = GameConstants.Minion.Egg.hatch_frames
   local frame_count = #hatch_frames
   local progress = 1 - (entity.hatch_timer / entity.hatch_time_max) -- 0 to 1
   local frame_idx = flr(progress * frame_count) + 1
   frame_idx = mid(1, frame_idx, frame_count)                        -- Clamp to valid range
   entity.sprite_index = hatch_frames[frame_idx]

   -- Decrement hatch timer
   if entity.hatch_timer and entity.hatch_timer > 0 then
      entity.hatch_timer = entity.hatch_timer - 1

      -- Hatch into chick when timer reaches 0
      if entity.hatch_timer <= 0 then
         Entities.spawn_chick(world, entity.x, entity.y)
         world.del(entity)
      end
   end
end
