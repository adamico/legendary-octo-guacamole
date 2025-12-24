local Collision = {}

require("constants")

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

Collision.CollisionHandlers = require("handlers")

-- Helper: Iterate over tiles overlapping a hitbox
local function for_each_tile(hb, callback)
    local x1 = flr(hb.x / GRID_SIZE)
    local y1 = flr(hb.y / GRID_SIZE)
    local x2 = flr((hb.x + hb.w - 0.001) / GRID_SIZE)
    local y2 = flr((hb.y + hb.h - 0.001) / GRID_SIZE)

    for tx = x1, x2 do
        for ty = y1, y2 do
            local tile = mget(tx, ty)
            local r1, r2, r3 = callback(tx, ty, tile)
            if r1 ~= nil then return r1, r2, r3 end
        end
    end
end

local function find_solid_tile(x, y, w, h)
    return for_each_tile({x = x, y = y, w = w, h = h}, function(tx, ty, tile)
        if tile and fget(tile, SOLID_FLAG) then return tx, ty end
    end)
end

Collision.find_solid_tile = find_solid_tile

local function is_solid(x, y, w, h)
    return find_solid_tile(x, y, w, h) ~= nil
end

Collision.is_solid = is_solid

local function get_guidance(tx, ty, axis)
    -- Check 4 neighbors for an open door
    local neighbors = {
        {dx = 1, dy = 0}, {dx = -1, dy = 0},
        {dx = 0, dy = 1}, {dx = 0, dy = -1}
    }
    for _, n in ipairs(neighbors) do
        local ntx, nty = tx + n.dx, ty + n.dy
        local tile = mget(ntx, nty)
        if tile == SPRITE_DOOR_OPEN then
            if axis == "x" and n.dy ~= 0 then return 0, n.dy end
            if axis == "y" and n.dx ~= 0 then return n.dx, 0 end
        end
    end
    return 0, 0
end

function Collision.get_overlapping_tile(x, y, w, h, target_sprite)
    return for_each_tile({x = x, y = y, w = w, h = h}, function(tx, ty, tile)
        if tile == target_sprite then return tx, ty, tile end
    end)
end

function Collision.check_trigger(entity, camera_manager)
    -- Isaac style: transition when player exits current room bounds
    local room = camera_manager.current_room
    if not room then return nil end

    local rpx = room.pixels
    local ex = entity.x
    local ey = entity.y

    -- Check if player center is outside room bounds
    local outside = ex < rpx.x or ex >= rpx.x + rpx.w or
       ey < rpx.y or ey >= rpx.y + rpx.h

    if outside then
        local handler = Collision.CollisionHandlers.tile["Player,Transition"]
        if handler then
            return handler(entity, 0, 0, 0, camera_manager)
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

function Collision.resolve_map(entity, room, camera_manager)
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

            -- Door guidance for player
            if entity.type == "Player" then
                local tx, ty = find_solid_tile(cx, cy, w, h)
                if tx then
                    local gdx, gdy = get_guidance(tx, ty, axis)
                    if gdx ~= 0 then entity.vel_x = gdx * 1.5 end
                    if gdy ~= 0 then entity.vel_y = gdy * 1.5 end
                end
            end

            entity["vel_"..axis] = 0
            entity["sub_"..axis] = 0
            return 0
        end
        return move
    end

    local mx = check("x", 0, 0)
    check("y", (entity.sub_x or 0) == 0 and 0 or mx, 0)

    -- Trigger check integrated into map resolution
    if entity.type == "Player" and camera_manager then
        Collision.check_trigger(entity, camera_manager)
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
