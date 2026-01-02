-- Entity lifecycle management: FSM initialization and state transitions (Pure ECS)
local machine = require("lib/lua-state-machine/statemachine")
local DeathHandlers = require("src/lifecycle/death_handlers")

local Lifecycle = {}

-- Create a simple FSM (no callbacks that capture entity references)
-- Timer reset is now handled by the animation system via state change detection
function Lifecycle.create_fsm()
   return machine.create({
      initial = "idle",
      events = {
         {name = "walk",    from = "idle",                           to = "walking"},
         {name = "stop",    from = "walking",                        to = "idle"},
         {name = "attack",  from = {"idle", "walking"},              to = "attacking"},
         {name = "hit",     from = {"idle", "walking", "attacking"}, to = "hurt"},
         {name = "die",     from = "*",                              to = "death"},
         {name = "recover", from = "hurt",                           to = "idle"},
         {name = "finish",  from = "attacking",                      to = "idle"}
      }
   })
end

--- Update FSM using direct buffer access (Pure ECS - no EntityProxy)
--- @param i integer Entity index in archetype buffers
--- @param id EntityID Entity ID
--- @param world ECSWorld ECS world
--- @param animatable table Animatable component buffer
--- @param fsm_buf table FSM component buffer
--- @param velocity table|nil Velocity component buffer (optional)
--- @param timers table|nil Timers component buffer (optional)
--- @param health table|nil Health component buffer (optional)
--- @param type_buf table|nil Type component buffer (optional)
function Lifecycle.update_entity(i, id, world, animatable, fsm_buf, velocity, timers, health, type_buf)
   -- Initialize FSM if needed
   local fsm = fsm_buf.value[i]
   if type(fsm) ~= "table" then
      fsm = Lifecycle.create_fsm()
      fsm_buf.value[i] = fsm
      animatable.anim_timer[i] = 0
   end

   -- Track previous state for animation timer reset
   local prev_state = fsm._prev_state
   local current_state = fsm.current

   -- Handle completed animations (Death / Attack finish)
   local complete_state = animatable.anim_complete_state[i]
   if complete_state then
      if complete_state == "death" then
         -- Death cleanup is handled separately (needs EntityProxy for death handlers)
         -- We'll flag it for processing by the death system
         if not fsm._death_handled then
            fsm._death_handled = true
            -- Queue death handler call (requires entity proxy for legacy handlers)
            Lifecycle._pending_deaths = Lifecycle._pending_deaths or {}
            local entity_type = type_buf and type_buf.value[i] or "default"
            table.insert(Lifecycle._pending_deaths, {id = id, type = entity_type})
         end
      elseif complete_state == "attacking" then
         local is_looping = animatable.anim_looping[i]
         if not is_looping and fsm:can("finish") then
            fsm:finish()
         end
      end
   end

   -- Can't transition out of death
   if fsm:is("death") then
      fsm._prev_state = current_state
      return
   end

   -- Handle movement transitions
   local vel_x = velocity and velocity.vel_x[i] or 0
   local vel_y = velocity and velocity.vel_y[i] or 0
   local is_moving = (abs(vel_x) > 0.1 or abs(vel_y) > 0.1)

   if is_moving then
      if fsm:can("walk") then fsm:walk() end
   else
      if fsm:can("stop") then fsm:stop() end
   end

   -- Hit transition (invuln timer indicates recent damage)
   local invuln = timers and timers.invuln_timer[i] or 0
   if invuln > 0 then
      fsm:hit()
   elseif fsm:is("hurt") then
      fsm:recover()
   end

   -- Death check
   local hp = health and health.hp[i]
   if hp and hp <= 0 then
      fsm:die()
   end

   -- Detect state change and reset animation timer
   if fsm.current ~= prev_state and prev_state ~= nil then
      animatable.anim_timer[i] = 0
   end
   fsm._prev_state = fsm.current
end

-- Process pending death handlers (called after main update loop)
function Lifecycle.process_deaths(world)
   if not Lifecycle._pending_deaths then return end

   local EntityProxy = require("src/utils/entity_proxy")
   for _, death in ipairs(Lifecycle._pending_deaths) do
      if world:entity_exists(death.id) then
         local handler = DeathHandlers[death.type] or DeathHandlers.default
         local proxy = EntityProxy.new(world, death.id)
         handler(world, proxy)
      end
   end
   Lifecycle._pending_deaths = nil
end

return Lifecycle
