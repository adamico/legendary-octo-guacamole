-- Wanderer behavior module
-- Provides random wandering for enemies without a current target

local Utils = require("utils")

-- Pick a random destination within radius of current position
local function pick_wander_target(entity)
    local radius = entity.wander_radius or 48
    local angle = rnd(1) * 2 * 3.14159            -- Random angle in radians
    local dist = rnd(radius * 0.5) + radius * 0.5 -- Between 50-100% of radius

    entity.wander_target_x = entity.x + cos(angle / (2 * 3.14159)) * dist
    entity.wander_target_y = entity.y + sin(angle / (2 * 3.14159)) * dist

    -- Set pause timer for when we reach target
    local pause_min = entity.wander_pause_min or 30
    local pause_max = entity.wander_pause_max or 90
    entity.wander_pause_duration = flr(rnd(pause_max - pause_min)) + pause_min
end

-- Initialize wandering state on entity if needed
local function init_wandering(entity)
    if not entity.wander_initialized then
        entity.wander_initialized = true
        entity.wander_state = "moving" -- "moving" or "pausing"
        entity.wander_timer = 0
        pick_wander_target(entity)
    end
end

-- Main wander behavior function
-- Returns: nothing, just updates entity velocity and direction
local function wander_behavior(entity)
    init_wandering(entity)

    local speed_mult = entity.wander_speed_mult or 0.5
    local speed = entity.speed * speed_mult

    if entity.wander_state == "pausing" then
        -- Stand still during pause
        entity.vel_x = 0
        entity.vel_y = 0

        entity.wander_timer = entity.wander_timer - 1
        if entity.wander_timer <= 0 then
            -- Done pausing, pick new target and start moving
            pick_wander_target(entity)
            entity.wander_state = "moving"
        end
    else
        -- Moving toward target
        local dx = entity.wander_target_x - entity.x
        local dy = entity.wander_target_y - entity.y
        local dist = sqrt(dx * dx + dy * dy)

        -- Check if we hit a wall last frame (flag set by collision system)
        if entity.hit_wall then
            -- Pick a new target when blocked
            pick_wander_target(entity)
            entity.hit_wall = false
            dx = entity.wander_target_x - entity.x
            dy = entity.wander_target_y - entity.y
            dist = sqrt(dx * dx + dy * dy)
        end

        if dist > 4 then
            -- Move toward target
            entity.vel_x = (dx / dist) * speed
            entity.vel_y = (dy / dist) * speed
            entity.dir_x = sgn(dx)
            entity.dir_y = sgn(dy)

            -- Update direction for animation system
            entity.current_direction = Utils.get_direction_name(dx, dy, entity.current_direction)
        else
            -- Reached target, start pausing
            entity.wander_state = "pausing"
            entity.wander_timer = entity.wander_pause_duration
            entity.vel_x = 0
            entity.vel_y = 0
        end
    end
end

-- Reset wandering state (call when switching to combat mode)
local function reset_wandering(entity)
    entity.wander_initialized = false
    entity.wander_state = nil
    entity.wander_timer = nil
    entity.wander_target_x = nil
    entity.wander_target_y = nil
end

return {
    update = wander_behavior,
    reset = reset_wandering,
}
