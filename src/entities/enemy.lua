-- Enemy entity factory (Type Object pattern)
-- All enemy types are defined as pure data in GameConstants.Enemy
-- This factory simply instantiates entities from their type config
local GameConstants = require("src/game/game_config")
local EntityUtils = require("src/utils/entity_utils")

local Enemy = {}

-- Unified spawn function using Type Object pattern
-- @param world - ECS world
-- @param x, y - spawn position
-- @param enemy_type - type key in GameConstants.Enemy (default: "Skulker")
-- @param instance_data - optional table with instance-specific overrides
function Enemy.spawn(world, x, y, enemy_type, instance_data)
    enemy_type = enemy_type or "Skulker"
    instance_data = instance_data or {}

    local config = GameConstants.Enemy[enemy_type]
    if not config then
        Log.error("Attempted to spawn unknown enemy type: "..tostring(enemy_type))
        return nil
    end

    -- 1. Base identity and physics state
    local enemy = {
        type = config.entity_type or "Enemy",
        enemy_type = enemy_type,
        x = x,
        y = y,
        vel_x = 0,
        vel_y = 0,
        sub_x = 0,
        sub_y = 0,
        dir_x = 0,
        dir_y = 1, -- Default facing down
        flip_x = false,
        hp = config.hp or 10,
        max_hp = config.hp or 10,
    }

    -- 2. Bulk copy all non-table values from config (stats, bounds, offsets)
    for k, v in pairs(config) do
        if type(v) ~= "table" then
            enemy[k] = v
        end
    end

    -- 3. Static table references (offsets, directional maps)
    enemy.sprite_index_offsets = config.sprite_index_offsets
    enemy.shadow_offsets = config.shadow_offsets
    enemy.shadow_widths = config.shadow_widths
    enemy.shadow_heights = config.shadow_heights

    -- 4. Dynamic/Behavior initialization
    if enemy.sprite_index_offsets then
        enemy.sprite_index = enemy.sprite_index_offsets.down
    end

    if enemy.is_shooter then
        -- Properties for generic shooter system
        enemy.shoot_cooldown = 0
        enemy.shoot_cooldown_duration = enemy.shoot_delay or 60
        enemy.projectile_type = "EnemyBullet"
        enemy.health_as_ammo = false -- Enemies have unlimited ammo

        -- Note: shooter and timers tags should be added in constants.lua enemy config
    end

    -- 5. Apply instance overrides
    for k, v in pairs(instance_data) do
        enemy[k] = v
    end

    -- 6. Create entity with tags from config
    return EntityUtils.spawn_entity(world, config.tags, enemy)
end

return Enemy
