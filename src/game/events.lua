-- Events module - Pub/Sub wrapper around beholder.lua
local beholder = require("lib/beholder.lua/beholder")

local Events = {}

-- Event Constants (use these instead of strings)
Events.ROOM_CLEAR = "room:clear"
Events.ROOM_TRANSITION = "room:transition"
Events.GAME_OVER = "game:over"
Events.MINIMAP_ZONE_ENTER = "minimap:zone_enter"
Events.MINIMAP_ZONE_EXIT = "minimap:zone_exit"
Events.LEVEL_UP = "game:level_up"
Events.VICTORY = "game:victory"

--- Subscribe to an event
-- @param event The event constant (e.g., Events.ROOM_CLEAR)
-- @param callback Function to call when event fires
-- @return Subscription ID (use with Events.off to unsubscribe)
function Events.on(event, callback)
   return beholder.observe(event, callback)
end

--- Unsubscribe from an event
-- @param id The subscription ID returned by Events.on
function Events.off(id)
   beholder.stopObserving(id)
end

--- Emit an event to all subscribers
-- @param event The event constant (e.g., Events.ROOM_CLEAR)
-- @param ... Arguments to pass to subscribers
function Events.emit(event, ...)
   beholder.trigger(event, ...)
end

--- Reset all subscriptions (call on scene exit)
function Events.reset()
   beholder.reset()
end

return Events
