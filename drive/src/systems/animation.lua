local machine = require("lua-state-machine/statemachine")
local GameConstants = require("constants")

local Animation = {}

-- Default animation timing (frames count and speed in ticks per frame)
Animation.DEFAULT_ANIM_PARAMS = {
   idle = {frames = 2, speed = 30},
   walking = {frames = 2, speed = 8},
   attacking = {frames = 4, speed = 6},
   hurt = {frames = 2, speed = 4},
   death = {frames = 4, speed = 8}
}

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
   return entity.current_direction or "down"
end

-- Get animation config for entity type
local function get_entity_config(entity)
   if entity.type == "Enemy" and entity.enemy_type then
      return GameConstants.Enemy[entity.enemy_type]
   end
   return GameConstants[entity.type]
end

function Animation.init_fsm(entity)
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
         -- Reset timer on ANY state entry (use specific state callbacks)
         onenteridle = function(self, name, from, to)
            entity.anim_timer = 0
         end,
         onenterwalking = function(self, name, from, to)
            entity.anim_timer = 0
         end,
         onenterattacking = function(self, name, from, to)
            entity.anim_timer = 0
         end,
         onenterhurt = function(self, name, from, to)
            entity.anim_timer = 0
         end,
         onenterdeath = function(self, name, from, to)
            entity.anim_timer = 0
         end,
         onstatechange = function(self, name, from, to)
            Log.trace("Animation state change for entity "..entity.type)
            Log.trace("Event: "..name)
            Log.trace("Current direction: "..entity.current_direction)
            Log.trace("From: "..from)
            Log.trace("To: "..to)
         end
      }
   })
   entity.anim_timer = 0
   entity.current_direction = "down"
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
      local new_dir = get_direction(entity)
      if new_dir ~= entity.current_direction then
         Log.trace("Direction change: "..entity.current_direction.." -> "..new_dir)
      end
      entity.current_direction = new_dir
   end


   if fsm:is("idle") then
      if is_moving then fsm:walk() end
   elseif fsm:is("walking") then
      if not is_moving then fsm:stop() end
   end

   -- Hit transition
   if entity.invuln_timer and entity.invuln_timer > 0 and not fsm:is("hurt") then
      if fsm:can("hit") then fsm:hit() end
   end

   -- Recover from hurt
   if fsm:is("hurt") and (entity.invuln_timer or 0) <= 0 then
      if fsm:can("recover") then fsm:recover() end
   end

   -- Death check (backup)
   if entity.hp and entity.hp <= 0 and not fsm:is("death") then
      if fsm:can("die") then fsm:die() end
   end
end

function Animation.animate(entity)
   if not entity.fsm then return end

   entity.anim_timer = (entity.anim_timer or 0) + 1

   local state = entity.fsm.current
   local direction = entity.current_direction or "down"
   local config = get_entity_config(entity)

   -- Get default animation parameters
   local anim_params = Animation.DEFAULT_ANIM_PARAMS[state]
   if not anim_params then return end

   local default_speed = anim_params.speed

   -- Get state-specific animation config
   local state_anim = nil
   if config and config.animations then
      local dir_anims = config.animations[direction]
      if dir_anims and dir_anims[state] then
         state_anim = dir_anims[state]
      elseif config.animations[state] then
         state_anim = config.animations[state]
      end
   end

   -- Helper: calculate frame index from durations array or single speed
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

   -- Determine animation type and calculate sprite indices
   local is_composite = false
   local has_indices = false
   local base_sprite = 0

   -- Default split_row based on entity height
   local default_split_row = flr((entity.height or 16) / 2)

   if state_anim then
      -- Check for composite sprite (top_indices/bottom_indices)
      if state_anim.top_indices ~= nil or state_anim.bottom_indices ~= nil then
         is_composite = true
         local top_indices = state_anim.top_indices or {0}
         local bottom_indices = state_anim.bottom_indices or {0}
         local durations = state_anim.durations
         local speed = state_anim.speed or default_speed

         -- Calculate frame for top and bottom (may have different counts)
         local top_frame, _ = get_frame_from_durations(durations, speed, entity.anim_timer, #top_indices)
         local bottom_frame, _ = get_frame_from_durations(durations, speed, entity.anim_timer, #bottom_indices)

         entity.sprite_top = top_indices[(top_frame % #top_indices) + 1] or 0
         entity.sprite_bottom = bottom_indices[(bottom_frame % #bottom_indices) + 1] or 0
         entity.split_row = state_anim.split_row or default_split_row
         entity.sprite_index = nil

         -- Check for explicit indices array (non-composite)
      elseif state_anim.indices ~= nil then
         has_indices = true
         local indices = state_anim.indices
         local durations = state_anim.durations
         local speed = state_anim.speed or default_speed

         local frame_idx, total_duration = get_frame_from_durations(durations, speed, entity.anim_timer, #indices)

         entity.sprite_top = nil
         entity.sprite_bottom = nil
         entity.split_row = nil
         entity.sprite_index = indices[(frame_idx % #indices) + 1] or 0

         -- Handle death/attack completion
         if state == "death" then
            if entity.anim_timer >= total_duration then
               local Combat = require("combat")
               local handler = Combat.DeathHandlers[entity.type] or Combat.DeathHandlers.default
               if not entity.death_cleanup_called then
                  entity.death_cleanup_called = true
                  handler(entity)
               end
            end
         elseif state == "attacking" then
            if entity.anim_timer >= total_duration then
               entity.fsm:finish()
            end
         end

         -- Standard base + frames
      elseif state_anim.base then
         local frames = state_anim.frames or anim_params.frames
         local durations = state_anim.durations
         local speed = state_anim.speed or default_speed

         local frame_idx, total_duration = get_frame_from_durations(durations, speed, entity.anim_timer, frames)

         entity.sprite_top = nil
         entity.sprite_bottom = nil
         entity.split_row = nil
         entity.sprite_index = state_anim.base + frame_idx

         -- Handle death/attack completion
         if state == "death" and entity.anim_timer >= total_duration then
            local Combat = require("combat")
            local handler = Combat.DeathHandlers[entity.type] or Combat.DeathHandlers.default
            if not entity.death_cleanup_called then
               entity.death_cleanup_called = true
               handler(entity)
            end
         elseif state == "attacking" and entity.anim_timer >= total_duration then
            entity.fsm:finish()
         end
      end
   else
      -- Fallback: use sprite_index_offsets
      if config and config.sprite_index_offsets then
         base_sprite = config.sprite_index_offsets[direction] or 0
      end
      local frames = anim_params.frames
      local frame_idx = flr(entity.anim_timer / default_speed) % frames

      entity.sprite_top = nil
      entity.sprite_bottom = nil
      entity.split_row = nil
      entity.sprite_index = base_sprite + frame_idx
   end

   -- Apply flip from animation config
   entity.flip = false
   if state_anim and state_anim.flip then
      entity.flip = true
   end
end

return Animation
