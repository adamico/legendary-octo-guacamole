-- Collision detection and resolution systems
local Collision = {}

-- Get hitbox bounds in world space
-- Returns {x, y, w, h} for collision detection
-- Supports per-direction hitboxes via entity.hitbox[direction] table
-- Falls back to hitbox_* properties, then width/height
local function get_hitbox(entity)
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
        y = entity.y + oy + (entity.sprite_offset_y or 0),
        w = w,
        h = h
    }
end

Collision.get_hitbox = get_hitbox
-- Tile Flags
local SOLID_FLAG = 0
local DOOR_FLAG = 1 -- Set this flag on door sprites in the GFX editor

Collision.CollisionHandlers = require("handlers")

local function is_solid(x, y, w, h)
    local x1 = flr(x / GRID_SIZE)
    local y1 = flr(y / GRID_SIZE)
    local x2 = flr((x + w - 0.001) / GRID_SIZE)
    local y2 = flr((y + h - 0.001) / GRID_SIZE)

    for tx = x1, x2 do
        for ty = y1, y2 do
            local tile = mget(tx, ty)
            if tile and fget(tile, SOLID_FLAG) then
                return true
            end
        end
    end
    return false
end

Collision.is_solid = is_solid

local function get_flagged_tile(x, y, w, h, flag)
    local x1 = flr(x / GRID_SIZE)
    local y1 = flr(y / GRID_SIZE)
    local x2 = flr((x + w - 0.001) / GRID_SIZE)
    local y2 = flr((y + h - 0.001) / GRID_SIZE)

    for tx = x1, x2 do
        for ty = y1, y2 do
            local tile = mget(tx, ty)
            if tile and fget(tile, flag) then
                return tx, ty, tile
            end
        end
    end
    return nil
end

Collision.get_flagged_tile = get_flagged_tile
Collision.DOOR_FLAG = DOOR_FLAG

function Collision.check_door_trigger(entity, room)
    local hb = get_hitbox(entity)
    local tx, ty, tile = get_flagged_tile(hb.x, hb.y, hb.w, hb.h, DOOR_FLAG)

    if tx then
        local handler = Collision.CollisionHandlers.tile["Player,Door"]
        if handler then
            return handler(entity, tx, ty, tile, room)
        end
    end

    return nil
end

function Collision.get_overlapping_tile(x, y, w, h, target_sprite)
    local x1 = flr(x / GRID_SIZE)
    local y1 = flr(y / GRID_SIZE)
    local x2 = flr((x + w - 0.001) / GRID_SIZE)
    local y2 = flr((y + h - 0.001) / GRID_SIZE)

    for tx = x1, x2 do
        for ty = y1, y2 do
            local tile = mget(tx, ty)
            if tile == target_sprite then
                return tx, ty, tile
            end
        end
    end
    return nil
end

function Collision.resolve_entities(entity1)
    world.sys("collidable", function(entity2)
        if entity1 == entity2 then return end

        local type1 = entity1.type or ""
        local type2 = entity2.type or ""
        local key = type1..","..type2
        local handler = Collision.CollisionHandlers.entity[key]

        if handler and Collision.check_overlap(entity1, entity2) then
            handler(entity1, entity2)
        end
    end)()
end

function Collision.resolve_map(entity, room)
    if entity.ignore_map_collision then
        return
    end

    local hb = get_hitbox(entity)
    local x = hb.x
    local y = hb.y
    local w = hb.w
    local h = hb.h

    local handler = Collision.CollisionHandlers.map[entity.type or ""]

    local function check(axis, vox, voy)
        local sub = entity["sub_"..axis]
        local vel = entity["vel_"..axis]
        local move = flr(sub + vel)
        if sub + vel < 0 and sub + vel ~= move then
            move = ceil(sub + vel) - 1
        end

        local cx = x + vox + (axis == "x" and move or 0)
        local cy = y + voy + (axis == "y" and move or 0)

        if is_solid(cx, cy, w, h) then
            if handler then handler(entity, cx, cy) end
            entity["vel_"..axis] = 0
            entity["sub_"..axis] = 0
            return 0
        end
        return move
    end

    local mx = check("x", 0, 0)
    check("y", entity.sub_x == 0 and 0 or mx, 0)

    if entity.type == "Player" and room then
        local tx, ty, tile = get_flagged_tile(hb.x, hb.y, hb.w, hb.h, DOOR_FLAG)
        if tx then
            local tile_handler = Collision.CollisionHandlers.tile["Player,Door"]
            if tile_handler then
                entity.door_trigger = tile_handler(entity, tx, ty, tile, room)
            end
        else
            entity.door_trigger = nil
        end
    end
end

function Collision.check_overlap(entity1, entity2)
    local hb1 = get_hitbox(entity1)
    local hb2 = get_hitbox(entity2)
    return hb1.x < hb2.x + hb2.w and
       hb1.x + hb1.w > hb2.x and
       hb1.y < hb2.y + hb2.h and
       hb1.y + hb1.h > hb2.y
end

return Collision
