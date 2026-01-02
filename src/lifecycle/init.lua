-- Lifecycle module aggregator (Pure ECS)
local lifecycle = require("src/lifecycle/lifecycle")
local death_handlers = require("src/lifecycle/death_handlers")

local Lifecycle = {}

-- Self-iterating update function using pure ECS queries (no EntityProxy in hot loop)
function Lifecycle.update(world)
   -- Query all required and optional components
   world:query({
      "animatable", "fsm", "velocity?", "timers?", "health?", "type?"
   }, function(ids, animatable, fsm_buf, velocity, timers, health, type_buf)
      for i = ids.first, ids.last do
         lifecycle.update_entity(
            i, ids[i], world,
            animatable, fsm_buf,
            velocity, timers, health, type_buf
         )
      end
   end)

   -- Process any pending death handlers (these still need EntityProxy for legacy handlers)
   lifecycle.process_deaths(world)
end

-- Export FSM creation for external use
Lifecycle.create_fsm = lifecycle.create_fsm
Lifecycle.DeathHandlers = death_handlers

return Lifecycle
