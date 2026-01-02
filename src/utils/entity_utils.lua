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
    -- Handle minion Type Object pattern
    if entity.minion_type then
        return GameConstants.Minion[entity.minion_type]
    end
    return GameConstants[entity.type]
end

--- Get configuration based on unrolled component values (ECS friendly)
--- @param type_val string Entity type
--- @param enemy_type_val string|nil Enemy type
--- @param proj_type_val string|nil Projectile type
--- @param minion_type_val string|nil Minion type
--- @return table|string|nil Configuration table
function Utils.get_component_config(type_val, enemy_type_val, proj_type_val, minion_type_val)
    if type_val == "Enemy" and enemy_type_val then
        return GameConstants.Enemy[enemy_type_val]
    elseif (type_val == "Projectile" or type_val == "EnemyProjectile") and proj_type_val then
        return GameConstants.Projectile[proj_type_val]
    elseif minion_type_val then
        return GameConstants.Minion[minion_type_val]
    else
        return GameConstants[type_val]
    end
end

--- Convert direction vector (dx, dy) to direction name string
--- @param dx number x component of direction
--- @param dy number y component of direction
--- @param default string|nil optional fallback value if movement is below threshold
--- @return string|nil "right", "left", "up", "down", or the provided default
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

--- Get center coordinates of an entity
--- @param entity table Entity with x, y, width, height fields
--- @return number cx Center x coordinate
--- @return number cy Center y coordinate
function Utils.get_center(entity)
    return entity.x + (entity.width or 16) / 2, entity.y + (entity.height or 16) / 2
end

--- Convert direction name string to vector (dx, dy)
--- @param dir_name string "right", "left", "up", or "down"
--- @return number dx Direction x component
--- @return number dy Direction y component
function Utils.get_direction_vector(dir_name)
    if dir_name == "up" then return 0, -1 end
    if dir_name == "down" then return 0, 1 end
    if dir_name == "left" then return -1, 0 end
    if dir_name == "right" then return 1, 0 end
    return 0, 1 -- Default to down
end

--- Get sprite index based on direction and config
--- @param config table Entity config table with sprite_index and optional sprite_index_offsets
--- @param direction string|nil Optional direction string ("up", "down", "left", "right")
--- @param default_index number|nil Optional default index if not found (defaults to 0)
--- @return number Sprite index
function Utils.get_sprite_index(config, direction, default_index)
    if config.sprite_index_offsets and direction then
        return config.sprite_index_offsets[direction]
    end
    return config.sprite_index or default_index or 0
end

---------------------------------------------------------------------------
-- Centralized Component Builders
-- These reduce repetition across entity factories
---------------------------------------------------------------------------

--- Parse comma-separated tags string into a set
--- @param tags_str string - comma-separated tags like "enemy,collidable,drawable"
--- @return table - set of tags {enemy=true, collidable=true, ...}
function Utils.parse_tags(tags_str)
    local tag_set = {}
    if tags_str then
        for tag in all(split(tags_str, ",")) do
            tag_set[tag] = true
        end
    end
    return tag_set
end

--- Build collidable component from config
--- Supports: config.hitboxes, config.hitbox, or individual hitbox_* fields
--- @param config table - entity config
--- @param defaults table|nil - optional defaults {map_collidable=true, w=16, h=16, ox=0, oy=0}
--- @return table - collidable component data
function Utils.build_collidable(config, defaults)
    defaults = defaults or {}

    local hitboxes = config.hitboxes or config.hitbox

    -- Fallback to properties or defaults
    if not hitboxes then
        hitboxes = {
            w = config.hitbox_width or defaults.w or 16,
            h = config.hitbox_height or defaults.h or 16,
            ox = config.hitbox_offset_x or defaults.ox or 0,
            oy = config.hitbox_offset_y or defaults.oy or 0,
        }
    end

    return {
        hitboxes = hitboxes,
        map_collidable = config.map_collidable ~= nil and config.map_collidable or (defaults.map_collidable ~= false),
    }
end

--- Build shadow component from config
--- @param config table - entity config with shadow_* fields
--- @return table - shadow component data
function Utils.build_shadow(config)
    return {
        shadow_offset_x = config.shadow_offset_x or 0,
        shadow_offset_y = config.shadow_offset_y or 0,
        shadow_width = config.shadow_width or 8,
        shadow_height = config.shadow_height or 3,
        shadow_offsets_x = config.shadow_offsets_x,
        shadow_offsets_y = config.shadow_offsets_y,
        shadow_widths = config.shadow_widths,
        shadow_heights = config.shadow_heights,
    }
end

--- Build drawable component from config
--- @param config table - entity config
--- @param direction string|nil - optional direction for sprite lookup
--- @param default_sprite number|nil - optional default sprite index
--- @return table - drawable component data
function Utils.build_drawable(config, direction, default_sprite)
    return {
        outline_color = config.outline_color,
        sort_offset_y = config.sort_offset_y or 0,
        sprite_index = Utils.get_sprite_index(config, direction, default_sprite),
        flip_x = false,
        flip_y = false,
    }
end

--- Build direction component with proper facing initialization
--- @param dir_x number - initial direction x (default 0)
--- @param dir_y number - initial direction y (default 1 = down)
--- @return table - direction component data
function Utils.build_direction(dir_x, dir_y)
    dir_x = dir_x or 0
    dir_y = dir_y or 1
    local facing = Utils.get_direction_name(dir_x, dir_y, "down")
    return {
        dir_x = dir_x,
        dir_y = dir_y,
        facing = facing,
    }
end

--- Build velocity component
--- @param vx number|nil - initial x velocity (default 0)
--- @param vy number|nil - initial y velocity (default 0)
--- @param vz number|nil - initial z velocity (default 0)
--- @return table - velocity component data
function Utils.build_velocity(vx, vy, vz)
    return {
        vel_x = vx or 0,
        vel_y = vy or 0,
        vel_z = vz or 0,
        sub_x = 0,
        sub_y = 0,
        knockback_vel_x = 0,
        knockback_vel_y = 0,
    }
end

--- Build size component from config
--- @param config table - entity config with width/height
--- @return table - size component data
function Utils.build_size(config)
    return {
        width = config.width or 16,
        height = config.height or 16,
    }
end

--- Build animatable component from config
--- @param config table - entity config with animations
--- @return table - animatable component data
function Utils.build_animatable(config)
    return {
        animations = config.animations,
        sprite_index_offsets = config.sprite_index_offsets,
        anim_timer = 0,
    }
end

--- Build acceleration component
--- @param config table - entity config with max_speed
--- @param defaults table|nil - defaults {accel=0, friction=0.5, gravity_z=0}
--- @return table - acceleration component data
function Utils.build_acceleration(config, defaults)
    defaults = defaults or {}
    return {
        accel = defaults.accel or 0,
        friction = defaults.friction or 0.5,
        max_speed = config.max_speed or defaults.max_speed or 0,
        gravity_z = defaults.gravity_z or 0,
    }
end

--- Build health component
--- @param config table - entity config with hp/max_health
--- @param defaults table|nil - defaults {overflow_banking=false}
--- @return table - health component data
function Utils.build_health(config, defaults)
    defaults = defaults or {}
    local hp = config.hp or config.max_health or 1
    return {
        hp = hp,
        max_hp = hp,
        overflow_hp = 0,
        overflow_banking = defaults.overflow_banking or false,
    }
end

--- Build timers component (zeroed)
--- @param overrides table|nil - optional timer overrides
--- @return table - timers component data
function Utils.build_timers(overrides)
    overrides = overrides or {}
    return {
        shoot_cooldown = overrides.shoot_cooldown or 0,
        invuln_timer = overrides.invuln_timer or 0,
        hp_drain_timer = overrides.hp_drain_timer or 0,
    }
end

--- Apply parsed tags to entity table, preserving existing component tables
--- @param entity table - entity data table
--- @param tag_set table - set of tags from parse_tags()
function Utils.apply_tags(entity, tag_set)
    for tag, _ in pairs(tag_set) do
        -- Only set tag if not already occupied by a component table
        if entity[tag] == nil then
            entity[tag] = true
        end
    end
end

--- Centralized entity spawning with automatic tag application
--- @param world ECSWorld The picobloc ECS world
--- @param tags table<string, boolean> Set of tags to apply to entity
--- @param entity_data table<string, any> Entity component data
--- @return EntityID The created entity ID
function Utils.spawn_entity(world, tags, entity_data)
    -- Apply tags to entity data
    for tag, _ in pairs(tags) do
        entity_data[tag] = true
    end

    local id = world:add_entity(entity_data)

    return id
end

return Utils
