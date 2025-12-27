local HitboxUtils = {}

-- Get hitbox bounds in world space
-- Returns {x, y, w, h} for collision detection
-- Supports per-direction hitboxes via entity.hitbox[direction] table
-- Falls back to hitbox_* properties, then width/height
function HitboxUtils.get_hitbox(entity)
    local w, h, ox, oy

    -- Check for direction-based hitbox table
    if entity.hitbox then
        local dir = entity.direction or entity.current_direction
        local dir_hb = dir and entity.hitbox[dir]
        if dir_hb then
            w = dir_hb.w
            h = dir_hb.h
            ox = dir_hb.ox or 0
            oy = dir_hb.oy or 0
        end
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
