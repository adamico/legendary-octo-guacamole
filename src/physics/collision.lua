local Collision = {}

local SpatialGrid = require("src/physics/spatial_grid")
local CollisionFilter = require("src/physics/collision_filter")
local HitboxUtils = require("src/utils/hitbox_utils")
Collision.CollisionHandlers = require("src/physics/handlers")
local MathUtils = require("src/utils/math_utils")

local collision_filter = CollisionFilter:new()

local get_hitbox = HitboxUtils.get_hitbox

local current_grid = nil

--- Helper: Iterate over tiles overlapping a hitbox
--- @param hb Hitbox
--- @param callback function(tx, ty, tile)
--- @return nil|number, nil|number, nil|number
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
    return nil, nil, nil
end

--- Find solid tile with entity-aware logic
---
--- @param x number
--- @param y number
--- @param w number
--- @param h number
--- @param entity Entity
--- @returns nil|number, nil|number, nil|number
local function find_solid_tile(x, y, w, h, entity)
    local stx, sty, stile = for_each_tile({x = x, y = y, w = w, h = h}, function(tx, ty, tile)
        if tile and fget(tile, SOLID_FLAG) then
            -- All projectiles (player and enemy) can fly over pits
            if fget(tile, FEATURE_FLAG_PIT) and entity and
               (entity.type == "Projectile" or entity.type == "EnemyProjectile") then
                return nil -- Projectiles ignore pits
            end
            return tx, ty, tile
        end
    end)

    return stx, sty, stile
end

Collision.find_solid_tile = find_solid_tile

local function is_solid(x, y, w, h, entity)
    return find_solid_tile(x, y, w, h, entity) ~= nil
end

Collision.is_solid = is_solid

--- Apply door guidance to nudge player toward nearby unlocked doors
---
--- This helps players "slide" into doorways when moving along walls
---
--- @param entity Entity
--- @param tx number
--- @param ty number
--- @param room Room
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

--- Check if player has exited room bounds and trigger transition
---
--- @param entity Entity
--- @param camera_manager CameraManager
--- @return nil|[number, number]
function Collision.check_trigger(entity, camera_manager)
    local room = camera_manager.current_room
    if not room then return nil end

    local rpx = room.pixels

    -- Use hitbox center for accurate boundary detection
    -- This prevents false triggers when tall sprites (like player with hitbox offset)
    -- have their entity.y above room boundary while hitbox is still inside
    local hb = get_hitbox(entity)
    local cx = hb.x + hb.w / 2
    local cy = hb.y + hb.h / 2

    -- Check if hitbox center is outside room bounds
    if cx < rpx.x or cx >= rpx.x + rpx.w or
       cy < rpx.y or cy >= rpx.y + rpx.h then
        -- Directly trigger transition (no need for handler indirection)
        return camera_manager:on_trigger(cx, cy)
    end

    return nil
end

--- Update the spatial grid once per frame
---
--- @param world The ECS world instance
function Collision.update_spatial_grid(world)
    current_grid = SpatialGrid:new(SPATIAL_GRID_CELL_SIZE)
    world.sys("collidable", function(e)
        current_grid:add(e, get_hitbox)
    end)()
end

--- Resolve collisions between entities
---
--- @param entity1 Entity
function Collision.resolve_entities(entity1)
    if not current_grid then
        -- Fallback if update_spatial_grid wasn't called, but better to call it explicitly
        current_grid = SpatialGrid:new(SPATIAL_GRID_CELL_SIZE)
        world.sys("collidable", function(e)
            current_grid:add(e, get_hitbox)
        end)()
    end

    -- Query nearby entities (spatial partitioning optimization)
    local nearby = current_grid:get_nearby(entity1, get_hitbox)

    -- Pre-calculate projectile segment if applicable (Continuous Collision Detection)
    local is_projectile = entity1.type == "Projectile" or entity1.type == "EnemyProjectile"
    local p_start_x, p_start_y, p_end_x, p_end_y
    if is_projectile and (abs(entity1.vel_x or 0) > 4 or abs(entity1.vel_y or 0) > 4) then
        -- Only strictly needed for fast moving objects, but let's be safe
        -- "Previous" position is roughly current - velocity
        -- (Assuming this runs AFTER velocity application, which it does in play.lua)
        local hb = get_hitbox(entity1)
        p_end_x = hb.x + hb.w / 2
        p_end_y = hb.y + hb.h / 2
        p_start_x = p_end_x - (entity1.vel_x or 0)
        p_start_y = p_end_y - (entity1.vel_y or 0)
    end

    for _, entity2 in ipairs(nearby) do
        -- Check collision layers (bitmasking - very fast)
        if collision_filter:can_collide(entity1, entity2) then
            local hit = false

            -- 1. Standard AABB Overlap
            if Collision.check_overlap(entity1, entity2) then
                hit = true
                -- 2. Continuous Collision Detection (Raycast) for fast projectiles
            elseif is_projectile and p_start_x then
                local hb2 = get_hitbox(entity2)
                if MathUtils.segment_intersects_aabb(p_start_x, p_start_y, p_end_x, p_end_y, hb2.x, hb2.y, hb2.w, hb2.h) then
                    hit = true
                end
            end

            if hit then
                -- Z-elevation filtering: Enemy projectiles above player's height miss
                if entity1.type == "EnemyProjectile" and entity2.type == "Player" then
                    local proj_z = entity1.z or 0
                    local target_height_z = entity2.height_z or 16
                    if proj_z > target_height_z then
                        hit = false -- Projectile is above player's vertical collision range
                    end
                end
            end

            if hit then
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

--- Resolve collisions between entity and map
---
--- @param entity Entity
--- @param room Room
--- @param camera_manager CameraManager
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

        local stx, sty, stile = find_solid_tile(cx, cy, w, h, entity, room)
        if stx then
            if handler then handler(entity, cx, cy, stx, sty, stile, room) end

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

--- Check if two entities overlap
---
--- @param entity1 Entity
--- @param entity2 Entity
--- @return boolean
function Collision.check_overlap(entity1, entity2)
    local hb1 = get_hitbox(entity1)
    local hb2 = get_hitbox(entity2)
    return hb1.x < hb2.x + hb2.w and
       hb1.x + hb1.w > hb2.x and
       hb1.y < hb2.y + hb2.h and
       hb1.y + hb1.h > hb2.y
end

return Collision
