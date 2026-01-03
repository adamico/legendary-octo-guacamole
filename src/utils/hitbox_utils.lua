local HitboxUtils = {}

function HitboxUtils.get_center(entity)
    local hitbox = HitboxUtils.get_hitbox(entity)
    return hitbox.x + hitbox.w / 2, hitbox.y + hitbox.h / 2
end

-- Get hitbox bounds in world space
-- Returns {x, y, w, h} for collision detection
-- Supports two formats:
--   1. Simple: entity.hitbox = {w, h, ox, oy} - same hitbox for all directions
--   2. Per-direction: entity.hitboxes = {down = {...}, up = {...}, ...}
-- Falls back to hitbox_* properties, then width/height
function HitboxUtils.get_hitbox(entity)
    local w, h, ox, oy

    -- Check for per-direction hitboxes table first
    if entity.hitboxes then
        local dir = entity.direction or entity.current_direction
        local dir_hb = dir and entity.hitboxes[dir]
        if dir_hb then
            w = dir_hb.w
            h = dir_hb.h
            ox = dir_hb.ox or 0
            oy = dir_hb.oy or 0
        end
    end

    -- Check for simple hitbox table (same for all directions)
    if not w and entity.hitbox and entity.hitbox.w then
        w = entity.hitbox.w
        h = entity.hitbox.h
        ox = entity.hitbox.ox or 0
        oy = entity.hitbox.oy or 0
    end

    -- Fallback to simple hitbox properties
    w = w or entity.hitbox_width or entity.width or 16
    h = h or entity.hitbox_height or entity.height or 16
    ox = ox or entity.hitbox_offset_x or 0
    oy = oy or entity.hitbox_offset_y or 0

    return {
        x = entity.x + ox + (entity.sprite_offset_x or 0),
        y = entity.y + oy + (entity.sprite_offset_y or 0) - (entity.z or 0),
        w = w,
        h = h
    }
end

return HitboxUtils
