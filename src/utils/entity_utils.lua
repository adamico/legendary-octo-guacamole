local GameConstants = require("src/game/game_config")
local Utils = {}

-- Get the configuration table for an entity based on its type and enemy_type
function Utils.get_config(entity)
    if entity.type == "Enemy" and entity.enemy_type then
        return GameConstants.Enemy[entity.enemy_type]
    end
    -- Handle projectile Type Object pattern
    if (entity.type == "Projectile" or entity.type == "EnemyProjectile") and entity.projectile_type then
        return GameConstants.Projectile[entity.projectile_type]
    end
    return GameConstants[entity.type]
end

-- Convert direction vector (dx, dy) to direction name string
-- @param dx - x component of direction (-1, 0, or 1)
-- @param dy - y component of direction (-1, 0, or 1)
-- @return "right", "left", "up", or "down"
-- Convert direction vector (dx, dy) to direction name string
-- @param dx - x component of direction
-- @param dy - y component of direction
-- @param default - optional fallback value if movement is below threshold
-- @return "right", "left", "up", "down", or the provided default
function Utils.get_direction_name(dx, dy, default)
    local threshold = 0.1
    if dx > threshold then
        return "right"
    elseif dx < -threshold then
        return "left"
    elseif dy > threshold then
        return "down"
    elseif dy < -threshold then
        return "up"
    end
    return default
end

-- Convert direction name string to vector (dx, dy)
-- @param dir_name - "right", "left", "up", or "down"
-- @return dx, dy
function Utils.get_direction_vector(dir_name)
    if dir_name == "up" then return 0, -1 end
    if dir_name == "down" then return 0, 1 end
    if dir_name == "left" then return -1, 0 end
    if dir_name == "right" then return 1, 0 end
    return 0, 1 -- Default to down
end

-- Centralized entity spawning with automatic shadow creation
-- @param world - ECS world
-- @param tags - comma-separated tag string (include "shadow" for auto shadow creation)
-- @param entity_data - entity property table
-- @return the created entity
function Utils.spawn_entity(world, tags, entity_data)
    local ent = world.ent(tags, entity_data)

    -- Auto-spawn shadow if entity has "shadow" tag
    if tags:find("shadow") then
        local Shadow = require("src/entities/shadow")
        Shadow.spawn(world, ent)
    end

    return ent
end

return Utils
