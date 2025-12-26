-- Utils module aggregator
local HitboxUtils = require("src/utils/hitbox_utils")
local EntityUtils = require("src/utils/entity_utils")

local Utils = {}

Utils.Hitbox = HitboxUtils
Utils.Entity = EntityUtils

return Utils
