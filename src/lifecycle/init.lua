-- Lifecycle module aggregator
local lifecycle = require("src/lifecycle/lifecycle")
local death_handlers = require("src/lifecycle/death_handlers")
local EntityProxy = require("src/utils/entity_proxy")

local Lifecycle = {}

-- Self-iterating update function
function Lifecycle.update(world)
   world:query({"animatable", "fsm"}, function(ids, animatable, fsm)
      for i = ids.first, ids.last do
         local e = EntityProxy.new(world, ids[i])
         lifecycle.update_fsm(e, world)
      end
   end)
end

Lifecycle.init = lifecycle.init_fsm
Lifecycle.DeathHandlers = death_handlers

return Lifecycle
