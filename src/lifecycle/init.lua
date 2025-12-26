-- Lifecycle module aggregator
local lifecycle = require("src/lifecycle/lifecycle")
local death_handlers = require("src/lifecycle/death_handlers")

local Lifecycle = {}

-- Self-iterating update function
function Lifecycle.update(world)
   world.sys("animatable", lifecycle.update_fsm)()
end

Lifecycle.init = lifecycle.init_fsm
Lifecycle.check_state_completion = lifecycle.check_state_completion
Lifecycle.DeathHandlers = death_handlers

return Lifecycle
