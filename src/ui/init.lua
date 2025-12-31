-- UI Module Aggregator
-- Exposes all UI-related modules through a single namespace

local Minimap = require("src/ui/minimap")
local Hud = require("src/ui/hud")
local XpBar = require("src/ui/xp_bar")

return {
   Minimap = Minimap,
   Hud = Hud,
   XpBar = XpBar,
}
