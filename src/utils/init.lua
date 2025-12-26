-- Utils module aggregator
local HitboxUtils = require("src/utils/hitbox_utils")
local EntityUtils = require("src/utils/entity_utils")
local Palette = require("src/utils/palette")
local TextUtils = require("src/utils/text_utils")
local Events = require("src/utils/events")

local Utils = {}

Utils.Hitbox = HitboxUtils
Utils.Entity = EntityUtils
Utils.Palette = Palette
Utils.Text = TextUtils
Utils.Events = Events

return Utils
