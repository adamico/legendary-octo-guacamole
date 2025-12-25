local Collision = {}

require("constants")
local GameConstants = require("constants")

-- Spatial grid for broad-phase collision detection
local function create_spatial_grid()
    return {}
end

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

local function add_to_grid(grid, entity)
    local hb = get_hitbox(entity)
    -- Add entity to all cells it overlaps
    local x1 = flr(hb.x / SPATIAL_GRID_CELL_SIZE)
    local y1 = flr(hb.y / SPATIAL_GRID_CELL_SIZE)
    local x2 = flr((hb.x + hb.w) / SPATIAL_GRID_CELL_SIZE)
    local y2 = flr((hb.y + hb.h) / SPATIAL_GRID_CELL_SIZE)

    for cx = x1, x2 do
        for cy = y1, y2 do
            local cell_key = cx..","..cy
            if not grid[cell_key] then
                grid[cell_key] = {}
            end
            table.insert(grid[cell_key], entity)
        end
    end
end

local function get_nearby_entities(grid, entity)
    local hb = get_hitbox(entity)
    local nearby = {}
    local seen = {}

    -- Check all cells entity overlaps
    local x1 = flr(hb.x / SPATIAL_GRID_CELL_SIZE)
    local y1 = flr(hb.y / SPATIAL_GRID_CELL_SIZE)
    local x2 = flr((hb.x + hb.w) / SPATIAL_GRID_CELL_SIZE)
    local y2 = flr((hb.y + hb.h) / SPATIAL_GRID_CELL_SIZE)

    for cx = x1, x2 do
        for cy = y1, y2 do
            local cell_key = cx..","..cy
            local cell = grid[cell_key]
            if cell then
                for _, other in ipairs(cell) do
                    if not seen[other] and other ~= entity then
                        seen[other] = true
                        table.insert(nearby, other)
                    end
                end
            end
        end
    end

    return nearby
end

Collision.get_hitbox = get_hitbox

Collision.CollisionHandlers = require("handlers")

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
local function apply_door_guidance(entity, hb)
    local function get_guidance(tx, ty, axis)
        -- Check 4 neighbors for an open door
        local neighbors = {
            {dx = 1, dy = 0}, {dx = -1, dy = 0},
            {dx = 0, dy = 1}, {dx = 0, dy = -1}
        }
        for _, n in ipairs(neighbors) do
            local ntx, nty = tx + n.dx, ty + n.dy
            local tile = mget(ntx, nty)
            if tile == DOOR_OPEN_TILE then
                if axis == "x" and n.dy ~= 0 then return 0, n.dy end
                if axis == "y" and n.dx ~= 0 then return n.dx, 0 end
            end
        end
        return 0, 0
    end

    -- Find solid tile player is hitting
    local tx, ty = find_solid_tile(hb.x, hb.y, hb.w, hb.h)
    if tx then
        local gdx, gdy = get_guidance(tx, ty, "x")
        if gdx ~= 0 then entity.vel_x = gdx * DOOR_GUIDANCE_MULTIPLIER end

        gdx, gdy = get_guidance(tx, ty, "y")
        if gdy ~= 0 then entity.vel_y = gdy * DOOR_GUIDANCE_MULTIPLIER end
    end
end

-- Check if two entities can collide based on collision layers (bitmasking)
local function can_collide(entity1, entity2)
    local type1 = entity1.type or ""
    local type2 = entity2.type or ""

    -- Get collision layers
    local layer1 = GameConstants.EntityCollisionLayer[type1]
    local layer2 = GameConstants.EntityCollisionLayer[type2]

    -- If either entity has no layer defined, allow collision (backward compatibility)
    if not layer1 or not layer2 then return true end

    -- Get collision mask for entity1
    local mask1 = GameConstants.CollisionMasks[layer1]
    if not mask1 then return true end

    -- Check if entity1's mask includes entity2's layer (bitwise AND)
    return (mask1 & layer2) ~= 0
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
    -- Build spatial grid for this frame
    local grid = create_spatial_grid()
    world.sys("collidable", function(e)
        add_to_grid(grid, e)
    end)()

    -- Only check nearby entities (spatial partitioning)
    local nearby = get_nearby_entities(grid, entity1)
    for _, entity2 in ipairs(nearby) do
        -- Check collision layers (bitmasking - very fast)
        if can_collide(entity1, entity2) then
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

        if is_solid(cx, cy, w, h) then
            if handler then handler(entity, cx, cy) end

            -- Apply door guidance for player only
            if entity.type == "Player" then
                apply_door_guidance(entity, {x = cx, y = cy, w = w, h = h})
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
