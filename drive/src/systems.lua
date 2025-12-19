-- Systems module: reusable ECS system functions
local Systems = {}

-- Input system: read controls and set direction
function Systems.controllable(entity)
    local left = btn(GameConstants.controls.move_left)
    local right = btn(GameConstants.controls.move_right)
    local up = btn(GameConstants.controls.move_up)
    local down = btn(GameConstants.controls.move_down)

    entity.dir_x = 0
    entity.dir_y = 0

    if left then entity.dir_x = -1 end
    if right then entity.dir_x = 1 end
    if up then entity.dir_y = -1 end
    if down then entity.dir_y = 1 end
end

-- Acceleration system: apply acceleration, friction, and clamp velocity
function Systems.acceleration(entity)
    local dx = entity.dir_x or 0
    local dy = entity.dir_y or 0

    -- Normalize acceleration for diagonal movement
    local accel = entity.accel
    if dx ~= 0 and dy ~= 0 then
        accel *= 0.7071
    end

    -- Apply acceleration
    entity.vel_x += dx * accel
    entity.vel_y += dy * accel

    -- Apply friction when no input on that axis
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

-- Velocity system: apply velocity to position with sub-pixel precision
function Systems.velocity(entity)
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

-- Drawable system: render entity sprite with animation
function Systems.drawable(entity)
    spr(t() * 30 % 30 < 15 and entity.sprite_index or entity.sprite_index + 1, entity.x, entity.y)
end

function Systems.draw_shadow(entity)
    local shadow_color = 1
    local x1, y1 = entity.x + 1, entity.y + 11
    local x2, y2 = entity.x + entity.width - 2, y1 + 6
    ovalfill(x1, y1, x2, y2, shadow_color)
end

return Systems
