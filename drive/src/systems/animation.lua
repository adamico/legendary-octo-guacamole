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

-- Get the direction name from entity dir_x/dir_y
local function get_direction(entity)
   local dx = entity.dir_x or 0
   local dy = entity.dir_y or 0

   -- Priority: horizontal over vertical for diagonals
   if dx > 0 then return "right" end
   if dx < 0 then return "left" end
   if dy > 0 then return "down" end
   if dy < 0 then return "up" end

   -- Default to down if no direction
   return "down"
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
         onenterstate = function(self, event, from, to)
            entity.anim_timer = 0
         end,
         onstatechange = function(self, event, from, to)
            Log.trace("Animation state change for entity "..entity.type)
            Log.trace("Event: "..event)
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

   -- Update current direction for animation lookup
   entity.current_direction = get_direction(entity)

   -- Handle movement states
   local is_moving = (abs(entity.vel_x or 0) > 0.1 or abs(entity.vel_y or 0) > 0.1)

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

   -- Get animation parameters
   local anim_params = Animation.DEFAULT_ANIM_PARAMS[state]
   if not anim_params then return end

   local frames = anim_params.frames
   local speed = anim_params.speed

   -- Override with entity-specific config if available
   if config and config.animations then
      local dir_anims = config.animations[direction]
      if dir_anims and dir_anims[state] then
         -- Per-direction, per-state config: { base = X, frames = Y, speed = Z }
         local state_anim = dir_anims[state]
         frames = state_anim.frames or frames
         speed = state_anim.speed or speed
      elseif config.animations[state] then
         -- Flat structure fallback: { offset = X, frames = Y, speed = Z }
         local state_anim = config.animations[state]
         frames = state_anim.frames or frames
         speed = state_anim.speed or speed
      end
   end

   -- Calculate current frame
   local frame = 0
   if state == "death" then
      frame = min(flr(entity.anim_timer / speed), frames - 1)

      -- When death animation completes, trigger cleanup
      if entity.anim_timer >= frames * speed then
         local Combat = require("combat")
         local handler = Combat.DeathHandlers[entity.type] or Combat.DeathHandlers.default
         if not entity.death_cleanup_called then
            entity.death_cleanup_called = true
            handler(entity)
         end
      end
   elseif state == "attacking" then
      frame = flr(entity.anim_timer / speed) % frames
      if entity.anim_timer >= frames * speed then
         entity.fsm:finish()
      end
   else
      frame = flr(entity.anim_timer / speed) % frames
   end

   -- Determine base sprite index (or composite top/bottom)
   local base_sprite = 0
   local is_composite = false
   local top_base, bottom_base = nil, nil
   local top_frames, bottom_frames = nil, nil
   local composite_speed = speed -- Use this for composite animations

   if config and config.animations then
      local dir_anims = config.animations[direction]
      if dir_anims and dir_anims[state] then
         local state_anim = dir_anims[state]

         -- Check for composite sprite with explicit frame indices
         if state_anim.top_indices ~= nil or state_anim.bottom_indices ~= nil then
            is_composite = true
            -- Use indices arrays for non-consecutive frames
            top_base = state_anim.top_indices or {state_anim.top_base or 0}
            bottom_base = state_anim.bottom_indices or {state_anim.bottom_base or 0}
            top_frames = #top_base
            bottom_frames = #bottom_base
            composite_speed = state_anim.speed or speed
            -- Check for composite sprite (top_base + bottom_base consecutive)
         elseif state_anim.top_base ~= nil and state_anim.bottom_base ~= nil then
            is_composite = true
            top_base = state_anim.top_base
            bottom_base = state_anim.bottom_base
            top_frames = state_anim.top_frames or frames
            bottom_frames = state_anim.bottom_frames or frames
            composite_speed = state_anim.speed or speed
         elseif state_anim.base then
            -- Standard per-direction, per-state base sprite
            base_sprite = state_anim.base
         end
      elseif config.sprite_index_offsets and config.sprite_index_offsets[direction] then
         -- Use direction offset + state offset (old flat structure)
         base_sprite = config.sprite_index_offsets[direction]
         if config.animations[state] and config.animations[state].offset then
            base_sprite = base_sprite + config.animations[state].offset
         end
      end
   elseif config and config.sprite_index_offsets then
      -- Fallback: just use direction offset
      base_sprite = config.sprite_index_offsets[direction] or 0
   end

   -- Apply flip from animation config or fallback to left direction check
   entity.flip = false
   if config and config.animations then
      local dir_anims = config.animations[direction]
      if dir_anims and dir_anims[state] and dir_anims[state].flip then
         entity.flip = true
      end
   end

   -- Set sprite indices for rendering
   if is_composite then
      -- Calculate frame index for top and bottom using composite speed
      local top_frame_idx = flr(entity.anim_timer / composite_speed) % top_frames
      local bottom_frame_idx = flr(entity.anim_timer / composite_speed) % bottom_frames

      -- Support both array indices and base+offset
      if type(top_base) == "table" then
         entity.sprite_top = top_base[top_frame_idx + 1] -- Lua 1-indexed
      else
         entity.sprite_top = top_base + top_frame_idx
      end

      if type(bottom_base) == "table" then
         entity.sprite_bottom = bottom_base[bottom_frame_idx + 1]
      else
         entity.sprite_bottom = bottom_base + bottom_frame_idx
      end

      -- Debug: log composite sprite values (only once per second to avoid spam)
      if entity.anim_timer % 60 == 1 then
         Log.trace("Composite sprite for "..entity.type.." dir="..direction.." state="..state)
         Log.trace("  top_base type="..type(top_base).." top_frames="..top_frames)
         Log.trace("  bottom_base type="..type(bottom_base).." bottom_frames="..bottom_frames)
         Log.trace("  top_frame_idx="..top_frame_idx.." bottom_frame_idx="..bottom_frame_idx)
         Log.trace("  sprite_top="..(entity.sprite_top or "nil").." sprite_bottom="..(entity.sprite_bottom or "nil"))
      end

      -- Fallback if indices are still nil (shouldn't happen but safety check)
      entity.sprite_top = entity.sprite_top or 0
      entity.sprite_bottom = entity.sprite_bottom or 0

      entity.sprite_index = nil -- Clear to signal composite mode
   else
      entity.sprite_top = nil
      entity.sprite_bottom = nil
      entity.sprite_index = base_sprite + frame
   end
end

return Animation
