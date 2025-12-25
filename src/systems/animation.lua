-- Pure animation system: sprite frame calculation and visual updates only
local Utils = require("utils")

local Animation = {}

-- Default speed fallback (ticks per frame)
local DEFAULT_SPEED = 8

-- Calculate frame index from durations array or single speed
local function get_frame_from_durations(durations, speed, timer, frame_count)
   if durations and #durations > 0 then
      local total_duration = 0
      for _, d in ipairs(durations) do
         total_duration = total_duration + d
      end
      local cycle_time = timer % total_duration
      local accumulated = 0
      for i, d in ipairs(durations) do
         accumulated = accumulated + d
         if cycle_time < accumulated then
            return i - 1, total_duration -- 0-indexed frame
         end
      end
      return #durations - 1, total_duration
   else
      return flr(timer / speed) % frame_count, frame_count * speed
   end
end

-- Helper to find the best matching animation config
local function find_animation_config(config, state, direction)
   if not config or not config.animations then return nil end
   local animations = config.animations

   -- 1. Try directional state: animations.down.walking
   local dir_anims = animations[direction]
   if dir_anims and type(dir_anims) == "table" then
      local state_anim = dir_anims[state]
      if state_anim then return state_anim end

      -- 2. Try directional idle fallback
      state_anim = dir_anims["idle"]
      if state_anim then return state_anim end

      -- 3. Try using dir_anims directly if it's an animation object
      if dir_anims.indices or dir_anims.base or dir_anims.top_indices then
         return dir_anims
      end
   end

   -- 4. Try global state fallback
   if animations[state] then return animations[state] end

   -- 5. Try global idle fallback
   return animations["idle"]
end

-- Main animation update: calculates sprite indices and flip flags
function Animation.animate(entity)
   -- Increment animation timer
   entity.anim_timer = (entity.anim_timer or 0) + 1

   -- Get current state and direction
   local state = entity.fsm and entity.fsm.current or "idle"
   local direction = entity.current_direction or entity.direction or "down"

   -- Update direction based on movement (only when moving)
   local is_moving = (abs(entity.vel_x or 0) > 0.1 or abs(entity.vel_y or 0) > 0.1)
   if is_moving then
      entity.current_direction = Utils.get_direction_name(
         entity.vel_x or 0,
         entity.vel_y or 0,
         entity.current_direction
      ) or direction
      direction = entity.current_direction
   end

   local config = Utils.get_config(entity)
   local state_anim = find_animation_config(config, state, direction)

   local current_frame_idx = 0
   local total_duration = 0

   if state_anim then
      local speed = state_anim.speed or DEFAULT_SPEED
      local durations = state_anim.durations

      if state_anim.top_indices or state_anim.bottom_indices then
         -- Composite sprite (top/bottom halves)
         local top_indices = state_anim.top_indices or {0}
         local bottom_indices = state_anim.bottom_indices or {0}

         local frame_idx, duration = get_frame_from_durations(durations, speed, entity.anim_timer, #top_indices)
         local b_frame_idx = get_frame_from_durations(durations, speed, entity.anim_timer, #bottom_indices)

         current_frame_idx = frame_idx
         total_duration = duration
         entity.sprite_top = top_indices[(frame_idx % #top_indices) + 1] or 0
         entity.sprite_bottom = bottom_indices[(b_frame_idx % #bottom_indices) + 1] or 0
         entity.split_row = state_anim.split_row or flr((entity.height or 16) / 2)
         entity.sprite_index = nil
      elseif state_anim.indices then
         -- Explicit indices array
         local indices = state_anim.indices
         local frame_idx, duration = get_frame_from_durations(durations, speed, entity.anim_timer, #indices)

         current_frame_idx = frame_idx
         total_duration = duration
         entity.sprite_top = nil
         entity.sprite_bottom = nil
         entity.split_row = nil
         entity.sprite_index = indices[(frame_idx % #indices) + 1] or 0
      elseif state_anim.base then
         -- Base sprite + frame offset
         local frames = state_anim.frames or 2
         local frame_idx, duration = get_frame_from_durations(durations, speed, entity.anim_timer, frames)

         current_frame_idx = frame_idx
         total_duration = duration
         entity.sprite_top = nil
         entity.sprite_bottom = nil
         entity.split_row = nil
         entity.sprite_index = state_anim.base + frame_idx
      end

      -- Apply flip configuration
      local fx = state_anim.flip_x or state_anim.flip or false
      local fy = state_anim.flip_y or false

      -- Per-frame flip support
      if state_anim.flips and state_anim.flips[current_frame_idx + 1] then
         local f = state_anim.flips[current_frame_idx + 1]
         fx = f.x ~= nil and f.x or fx
         fy = f.y ~= nil and f.y or fy
      end

      entity.flip_x = fx
      entity.flip_y = fy
   else
      -- Fallback: simple 2-frame loop using sprite_index_offsets
      local base_sprite = 0
      if config and config.sprite_index_offsets then
         base_sprite = config.sprite_index_offsets[direction] or 0
      end
      current_frame_idx = flr(entity.anim_timer / DEFAULT_SPEED) % 2
      total_duration = DEFAULT_SPEED * 2

      entity.sprite_top = nil
      entity.sprite_bottom = nil
      entity.split_row = nil
      entity.sprite_index = base_sprite + current_frame_idx
      entity.flip_x = false
      entity.flip_y = false
   end

   -- Notify lifecycle system if animation completed
   if total_duration > 0 and entity.anim_timer >= total_duration then
      local Lifecycle = require("lifecycle")
      local is_looping = state_anim and state_anim.loop
      Lifecycle.check_state_completion(entity, state, entity.anim_timer, total_duration, is_looping)
   end
end

return Animation
