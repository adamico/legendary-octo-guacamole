-- Physics and movement systems
-- Handles acceleration, friction, and velocity application

local Physics = {}

-- Internal: apply acceleration, friction, and clamp velocity
local function apply_acceleration(entity)
    local dx = entity.dir_x or 0
    local dy = entity.dir_y or 0

    -- Normalize acceleration for diagonal movement
    local accel = entity.accel
    if dx ~= 0 and dy ~= 0 then
        accel = accel * 0.7071 -- sqrt(2)/2 for diagonal
    end

    -- Apply acceleration
    if dx ~= 0 then entity.vel_x += dx * accel end
    if dy ~= 0 then entity.vel_y += dy * accel end

    -- Apply friction when not actively moving in a direction
    if dx == 0 then entity.vel_x *= entity.friction end
    if dy == 0 then entity.vel_y *= entity.friction end

    -- Clamp to max speed
    local max_spd = entity.max_speed
    entity.vel_x = mid(-max_spd, entity.vel_x, max_spd)
    entity.vel_y = mid(-max_spd, entity.vel_y, max_spd)

    -- Stop completely if very slow (prevents drift)
    if abs(entity.vel_x) < 0.1 then entity.vel_x = 0 end
    if abs(entity.vel_y) < 0.1 then entity.vel_y = 0 end
end

-- Internal: apply velocity to position with sub-pixel precision
local function apply_velocity(entity)
    -- Initialize sub-pixel accumulators if not present
    entity.sub_x = entity.sub_x or 0
    entity.sub_y = entity.sub_y or 0

    -- Accumulate velocity (including fractional parts)
    entity.sub_x += entity.vel_x
    entity.sub_y += entity.vel_y

    -- Extract whole pixel movement
    local move_x = flr(entity.sub_x)
    local move_y = flr(entity.sub_y)

    -- Handle negative values correctly (flr rounds toward negative infinity)
    if entity.sub_x < 0 and entity.sub_x ~= move_x then
        move_x = ceil(entity.sub_x) - 1
    end
    if entity.sub_y < 0 and entity.sub_y ~= move_y then
        move_y = ceil(entity.sub_y) - 1
    end

    -- Apply whole pixel movement
    entity.x += move_x
    entity.y += move_y

    -- Keep the remainder for next frame
    entity.sub_x -= move_x
    entity.sub_y -= move_y
end

-- Update acceleration for all entities with acceleration tag
-- @param world - ECS world
function Physics.acceleration(world)
    world.sys("acceleration", apply_acceleration)()
end

-- Update velocity for all entities with velocity tag
-- @param world - ECS world
function Physics.velocity(world)
    world.sys("velocity", apply_velocity)()
end

return Physics
