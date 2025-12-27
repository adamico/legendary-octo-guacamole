local GameConstants = require("src/game/game_config")

local CollisionFilter = Class("CollisionFilter")

function CollisionFilter:initialize()
    self.layer_map = GameConstants.EntityCollisionLayer
    self.masks = GameConstants.CollisionMasks
end

function CollisionFilter:can_collide(entity1, entity2)
    local type1 = entity1.type or ""
    local type2 = entity2.type or ""

    local layer1 = self.layer_map[type1]
    local layer2 = self.layer_map[type2]

    -- Backward compatibility: allow collision if either entity has no layer
    if not layer1 or not layer2 then return true end

    local mask1 = self.masks[layer1]
    if not mask1 then return true end

    -- Bitwise AND check
    return (mask1 & layer2) ~= 0
end

return CollisionFilter
