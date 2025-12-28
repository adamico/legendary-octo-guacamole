-- UI Module Aggregator
-- Exposes all UI-related modules through a single namespace

local Minimap = require("src/ui/minimap")
local Hud = require("src/ui/hud")

return {
   Minimap = Minimap,
   Hud = Hud
}
