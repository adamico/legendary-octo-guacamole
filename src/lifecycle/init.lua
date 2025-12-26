-- Lifecycle module aggregator
local lifecycle = require("lifecycle/lifecycle")
local death_handlers = require("lifecycle/death_handlers")

local Lifecycle = {}

Lifecycle.update = lifecycle.update_fsm
Lifecycle.init = lifecycle.init_fsm
Lifecycle.check_state_completion = lifecycle.check_state_completion
Lifecycle.DeathHandlers = death_handlers

return Lifecycle
