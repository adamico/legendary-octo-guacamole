local Collision = {}

local SpatialGrid = require("src/physics/spatial_grid")
local CollisionFilter = require("src/physics/collision_filter")
local HitboxUtils = require("src/utils/hitbox_utils")

-- Create persistent filter instance (doesn't change per frame)
local collision_filter = CollisionFilter:new()

-- Local reference for convenience within this module
local get_hitbox = HitboxUtils.get_hitbox

Collision.CollisionHandlers = require("src/physics/handlers")

-- Helper: Iterate over tiles overlapping a hitbox
local function for_each_tile(hb, callback)
    local x1 = flr(hb.x / GRID_SIZE)
    local y1 = flr(hb.y / GRID_SIZE)
    local x2 = flr((hb.x + hb.w - TILE_EDGE_TOLERANCE) / GRID_SIZE)
    local y2 = flr((hb.y + hb.h - TILE_EDGE_TOLERANCE) / GRID_SIZE)

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

-- Apply door guidance to nudge player toward nearby unlocked doors
-- This helps players "slide" into doorways when moving along walls
local function apply_door_guidance(entity, tx, ty, room)
    if not room or not room.doors then return end

    for dir, door in pairs(room.doors) do
        -- Only guide toward open doors
        if door.sprite == DOOR_OPEN_TILE then
            local dpos = room:get_door_tile(dir)
            if dpos then
                -- Door is in same column?
                if tx == dpos.tx then
                    -- Door is adjacent on Y axis?
                    if abs(ty - dpos.ty) == 1 then
                        entity.vel_y = (dpos.ty > ty and 1 or -1) * DOOR_GUIDANCE_MULTIPLIER
                        return -- Stop after first match
                    end
                end
                -- Door is in same row?
                if ty == dpos.ty then
                    -- Door is adjacent on X axis?
                    if abs(tx - dpos.tx) == 1 then
                        entity.vel_x = (dpos.tx > tx and 1 or -1) * DOOR_GUIDANCE_MULTIPLIER
                        return -- Stop after first match
                    end
                end
            end
        end
    end
end

-- Check if player has exited room bounds and trigger transition
function Collision.check_trigger(entity, camera_manager)
    local room = camera_manager.current_room
    if not room then return nil end

    local rpx = room.pixels

    -- Check if player center is outside room bounds
    if entity.x < rpx.x or entity.x >= rpx.x + rpx.w or
       entity.y < rpx.y or entity.y >= rpx.y + rpx.h then
        -- Directly trigger transition (no need for handler indirection)
        return camera_manager:on_trigger(entity.x, entity.y)
    end

    return nil
end

function Collision.resolve_entities(entity1)
    -- Create spatial grid for this frame
    local grid = SpatialGrid:new(SPATIAL_GRID_CELL_SIZE)

    -- Populate grid with all collidable entities
    world.sys("collidable", function(e)
        grid:add(e, get_hitbox)
    end)()

    -- Query nearby entities (spatial partitioning optimization)
    local nearby = grid:get_nearby(entity1, get_hitbox)

    for _, entity2 in ipairs(nearby) do
        -- Check collision layers (bitmasking - very fast)
        if collision_filter:can_collide(entity1, entity2) then
            -- Check overlap (narrow-phase AABB)
            if Collision.check_overlap(entity1, entity2) then
                local type1 = entity1.type or ""
                local type2 = entity2.type or ""
                local key = type1..","..type2
                local handler = Collision.CollisionHandlers.entity[key]

                if handler then
                    handler(entity1, entity2)
                end
            end
        end
    end
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

        local stx, sty = find_solid_tile(cx, cy, w, h)
        if stx then
            if handler then handler(entity, cx, cy) end

            -- Apply door guidance for player only
            if entity.type == "Player" then
                apply_door_guidance(entity, stx, sty, room)
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
