-- Lifecycle module aggregator
local lifecycle = require("src/lifecycle/lifecycle")
local death_handlers = require("src/lifecycle/death_handlers")

local Lifecycle = {}

-- Self-iterating update function
function Lifecycle.update(world)
   world.sys("animatable", function(e) lifecycle.update_fsm(e, world) end)()
end

Lifecycle.init = lifecycle.init_fsm
Lifecycle.DeathHandlers = death_handlers

return Lifecycle
