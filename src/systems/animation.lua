-- Pure animation system: sprite frame calculation (Picobloc ECS)
local EntityUtils = require("src/utils/entity_utils")
local GameConstants = require("src/game/game_config")

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

-- Update all animations
function Animation.update(world)
   -- Access optional components directly
   local comps = world.components
   local vel = comps.velocity
   local fsm = comps.fsm
   -- REVIEW: do we need to check each ai, or entity types?
   local enemy_ai = comps.enemy_ai
   local minion_ai = comps.minion_ai
   local enemy_type = comps.enemy_type
   local proj_type = comps.projectile_type
   local minion_type = comps.minion_type

   local query = {
      "drawable", "animatable", "direction", "type"
   }

   world:query(query, function(ids, drawable, animatable, dir, type_c)
      for i = ids.first, ids.last do
         -- Increment Timer
         local timer = (animatable.anim_timer[i] or 0) + 1
         animatable.anim_timer[i] = timer

         -- Resolve FSM State
         local fsm_instance = (fsm and fsm.value[i])
            or (enemy_ai and enemy_ai.fsm[i])
            or (minion_ai and minion_ai.fsm[i])

         local state = fsm_instance and fsm_instance.current or "idle"

         -- Resolve Direction
         -- If moving, update 'facing' (stored in component for persistence)
         local facing = dir.facing[i] or "down"
         if vel and vel.vel_x[i] then
            local vx = vel.vel_x[i]
            local vy = vel.vel_y[i]
            if abs(vx) > 0.1 or abs(vy) > 0.1 then
               facing = EntityUtils.get_direction_name(vx, vy, facing)
               dir.facing[i] = facing
            end
         end

         -- Resolve Config
         local enemy_t_val = enemy_type and enemy_type.value[i]
         local proj_t_val = proj_type and proj_type.value[i]
         local minion_t_val = minion_type and minion_type.value[i]

         local config = EntityUtils.get_component_config(type_c.value[i], enemy_t_val, proj_t_val, minion_t_val)
         local state_anim = find_animation_config(config, state, facing)

         -- Resolve Animation Frame
         local current_frame_idx = 0
         local total_duration = 0

         -- Output Declarations
         local spr_idx, spr_top, spr_bot, split
         local fx, fy = false, false

         if state_anim then
            local speed = state_anim.speed or DEFAULT_SPEED
            local durations = state_anim.durations

            if state_anim.top_indices or state_anim.bottom_indices then
               -- Composite
               local top_indices = state_anim.top_indices or {0}
               local bot_indices = state_anim.bottom_indices or {0}

               local frame_idx, dur = get_frame_from_durations(durations, speed, timer, #top_indices)
               local b_frame_idx = get_frame_from_durations(durations, speed, timer, #bot_indices)

               current_frame_idx = frame_idx
               total_duration = dur

               spr_top = top_indices[(frame_idx % #top_indices) + 1] or 0
               spr_bot = bot_indices[(b_frame_idx % #bot_indices) + 1] or 0
               split = state_anim.split_row
               -- We use size/2 based split logic in renderer if nil?
               -- Renderer uses `draw_outlined_composite` helper which defaults to flr(height/2)
               -- We pass `split_row` component.
            elseif state_anim.indices then
               -- Explicit Indices
               local indices = state_anim.indices
               local frame_idx, dur = get_frame_from_durations(durations, speed, timer, #indices)
               current_frame_idx = frame_idx
               total_duration = dur
               spr_idx = indices[(frame_idx % #indices) + 1] or 0
            elseif state_anim.base then
               -- Base + Offset
               local frames = state_anim.frames or 2
               local frame_idx, dur = get_frame_from_durations(durations, speed, timer, frames)
               current_frame_idx = frame_idx
               total_duration = dur
               spr_idx = state_anim.base + frame_idx
            end

            -- Flips
            local afx = state_anim.flip_x or state_anim.flip or false
            local afy = state_anim.flip_y or false

            if state_anim.flips and state_anim.flips[current_frame_idx + 1] then
               local f = state_anim.flips[current_frame_idx + 1]
               afx = f.x ~= nil and f.x or afx
               afy = f.y ~= nil and f.y or afy
            end
            fx, fy = afx, afy
         else
            -- Fallback: Simple 2-frame loop using sprite_index_offsets
            local base = 0
            if config and config.sprite_index_offsets then
               -- Check for directional sprite offsets
               if type(config.sprite_index_offsets) == "table" then
                  base = config.sprite_index_offsets[facing] or 0
                  -- Legacy fallback logic for left facing using right sprite + flip?
                  -- "left" might not exist in offsets, defaulting to right + flip.
                  -- Picobloc migration: let's reimplement `change_sprite` logic basically.
                  if not config.sprite_index_offsets["left"] and facing == "left" then
                     base = config.sprite_index_offsets["right"] or 0
                     fx = true
                  end
               else
                  base = config.sprite_index_offsets -- Number
               end
            end
            current_frame_idx = flr(timer / DEFAULT_SPEED) % 2
            total_duration = DEFAULT_SPEED * 2
            spr_idx = base + current_frame_idx
         end

         -- Write outputs to component buffers
         drawable.sprite_index[i] = spr_idx or 0
         drawable.sprite_top[i] = spr_top or 0
         drawable.sprite_bottom[i] = spr_bot or 0
         drawable.split_row[i] = split or 0
         drawable.flip_x[i] = fx
         drawable.flip_y[i] = fy

         -- Lifecycle Flags
         if total_duration > 0 and timer >= total_duration then
            animatable.anim_complete_state[i] = state
            animatable.anim_looping[i] = state_anim and state_anim.loop
         else
            animatable.anim_complete_state[i] = nil
         end
      end
   end)
end

return Animation
