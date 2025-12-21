local machine = require("lua-state-machine/statemachine")
local GameConstants = require("constants")

local Animation = {}

-- Valid animation states
local VALID_STATES = {idle = true, walking = true, attacking = true, hurt = true, death = true}

-- Default speed fallback (ticks per frame)
local DEFAULT_SPEED = 8

-- Get the direction name from entity velocity (for animation facing)
local function get_direction(entity)
   local vx = entity.vel_x or 0
   local vy = entity.vel_y or 0

   -- Priority: horizontal over vertical for diagonals
   if vx > 0.1 then return "right" end
   if vx < -0.1 then return "left" end
   if vy > 0.1 then return "down" end
   if vy < -0.1 then return "up" end

   -- Return current direction if velocity is near zero (preserve last)
   return entity.current_direction
end

-- Get animation config for entity type
local function get_entity_config(entity)
   if entity.type == "Enemy" and entity.enemy_type then
      return GameConstants.Enemy[entity.enemy_type]
   end
   return GameConstants[entity.type]
end

-- Calculate frame index from durations array or single speed
local function get_frame_from_durations(durations, speed, timer, frame_count)
   if durations and #durations > 0 then
      -- Per-frame durations: calculate total cycle time
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
      -- Single speed for all frames
      return flr(timer / speed) % frame_count, frame_count * speed
   end
end

-- Clear composite sprite properties
local function clear_composite_props(entity)
   entity.sprite_top = nil
   entity.sprite_bottom = nil
   entity.split_row = nil
end

-- Handle animation-triggered state completion (death cleanup, attack finish)
local function handle_state_completion(entity, state, timer, total_duration)
   if state == "death" and timer >= total_duration then
      local Combat = require("combat")
      local handler = Combat.DeathHandlers[entity.type] or Combat.DeathHandlers.default
      if not entity.death_cleanup_called then
         entity.death_cleanup_called = true
         handler(entity)
      end
   elseif state == "attacking" and timer >= total_duration then
      entity.fsm:finish()
   end
end

function Animation.init_fsm(entity)
   -- Timer reset function used by all state entry callbacks
   local function reset_timer()
      entity.anim_timer = 0
   end

   entity.fsm = machine.create({
      initial = "idle",
      events = {
         {name = "walk",    from = "idle",                           to = "walking"},
         {name = "stop",    from = "walking",                        to = "idle"},
         {name = "attack",  from = {"idle", "walking"},              to = "attacking"},
         {name = "hit",     from = {"idle", "walking", "attacking"}, to = "hurt"},
         {name = "die",     from = "*",                              to = "death"},
         {name = "recover", from = "hurt",                           to = "idle"},
         {name = "finish",  from = "attacking",                      to = "idle"}
      },
      callbacks = {
         onenteridle = reset_timer,
         onenterwalking = reset_timer,
         onenterattacking = reset_timer,
         onenterhurt = reset_timer,
         onenterdeath = reset_timer
      }
   })
   entity.anim_timer = 0
   entity.current_direction = entity.direction or entity.current_direction or "down"
end

function Animation.update_fsm(entity)
   if not entity.fsm then
      Animation.init_fsm(entity)
   end

   local fsm = entity.fsm

   -- Can't transition out of death
   if fsm:is("death") then return end

   -- Handle movement states
   local is_moving = (abs(entity.vel_x or 0) > 0.1 or abs(entity.vel_y or 0) > 0.1)

   -- Only update direction when actually moving (preserve last direction when idle)
   if is_moving then
      entity.current_direction = get_direction(entity)
   end

   -- Movement transitions (silently fail if not valid)
   if is_moving then
      fsm:walk()
   else
      fsm:stop()
   end

   -- Hit transition (invuln timer indicates recent damage)
   if entity.invuln_timer and entity.invuln_timer > 0 then
      fsm:hit()
   end

   -- Recover from hurt
   if (entity.invuln_timer or 0) <= 0 then
      fsm:recover()
   end

   -- Death check
   if entity.hp and entity.hp <= 0 then
      fsm:die()
   end
end

function Animation.animate(entity)
   if not entity.fsm then return end

   entity.anim_timer += 1

   local state = entity.fsm.current
   local direction = entity.current_direction
   local config = get_entity_config(entity)

   -- Skip invalid states
   if not VALID_STATES[state] then return end

   -- Get state-specific animation config
   local state_anim
   if config and config.animations then
      -- 1. Try directional state: animations.down.walking
      local dir_anims = config.animations[direction]
      if dir_anims and type(dir_anims) == "table" then
         state_anim = dir_anims[state]
         -- 2. Try directional idle fallback: animations.down.idle
         if not state_anim then
            state_anim = dir_anims["idle"]
         end

         -- 2.5 Try using dir_anims directly if it's an animation object (no states)
         if not state_anim and (dir_anims.indices or dir_anims.base or dir_anims.top_indices) then
            state_anim = dir_anims
         end
      end

      -- 3. Try global state fallback: animations.walking
      if not state_anim then
         state_anim = config.animations[state]
      end

      -- 4. Try global idle fallback: animations.idle
      if not state_anim then
         state_anim = config.animations["idle"]
      end
   end

   -- Default split_row based on entity height
   local default_split_row = flr((entity.height or 16) / 2)

   -- Track the current frame for per-frame flip support
   local current_frame_idx = 0

   if state_anim then
      -- Composite sprite (top_indices/bottom_indices)
      if state_anim.top_indices or state_anim.bottom_indices then
         local top_indices = state_anim.top_indices or {0}
         local bottom_indices = state_anim.bottom_indices or {0}
         local durations = state_anim.durations
         local speed = state_anim.speed or DEFAULT_SPEED

         local top_frame = get_frame_from_durations(durations, speed, entity.anim_timer, #top_indices)
         local bottom_frame = get_frame_from_durations(durations, speed, entity.anim_timer, #bottom_indices)

         current_frame_idx = top_frame -- Use top frame for flip lookup
         entity.sprite_top = top_indices[(top_frame % #top_indices) + 1] or 0
         entity.sprite_bottom = bottom_indices[(bottom_frame % #bottom_indices) + 1] or 0
         entity.split_row = state_anim.split_row or default_split_row
         entity.sprite_index = nil

         -- Explicit indices array (non-composite)
      elseif state_anim.indices then
         local indices = state_anim.indices
         local durations = state_anim.durations
         local speed = state_anim.speed or DEFAULT_SPEED

         local frame_idx, total_duration = get_frame_from_durations(durations, speed, entity.anim_timer, #indices)
         current_frame_idx = frame_idx

         clear_composite_props(entity)
         entity.sprite_index = indices[(frame_idx % #indices) + 1] or 0
         handle_state_completion(entity, state, entity.anim_timer, total_duration)

         -- Standard base + frames
      elseif state_anim.base then
         local frames = state_anim.frames or 2
         local durations = state_anim.durations
         local speed = state_anim.speed or DEFAULT_SPEED

         local frame_idx, total_duration = get_frame_from_durations(durations, speed, entity.anim_timer, frames)
         current_frame_idx = frame_idx

         clear_composite_props(entity)
         entity.sprite_index = state_anim.base + frame_idx
         handle_state_completion(entity, state, entity.anim_timer, total_duration)
      end
   else
      -- Fallback: use sprite_index_offsets
      local base_sprite = 0
      if config and config.sprite_index_offsets then
         base_sprite = config.sprite_index_offsets[direction] or 0
      end
      current_frame_idx = flr(entity.anim_timer / DEFAULT_SPEED) % 2

      clear_composite_props(entity)
      entity.sprite_index = base_sprite + current_frame_idx
   end

   -- Apply flip from animation config
   local fx = state_anim and (state_anim.flip_x or state_anim.flip) or false
   local fy = state_anim and state_anim.flip_y or false

   -- Support per-frame flips
   if state_anim and state_anim.flips and state_anim.flips[current_frame_idx + 1] then
      local f = state_anim.flips[current_frame_idx + 1]
      fx = f.x ~= nil and f.x or fx
      fy = f.y ~= nil and f.y or fy
   end

   entity.flip_x = fx
   entity.flip_y = fy
end

return Animation
