-- Room Renderer
-- Handles visual rendering of rooms, adjacent room masking, and void coverage
--
-- This module extracts rendering-related functions from play.lua to keep
-- the scene file focused on orchestration.

local DungeonManager = require("src/world/dungeon_manager")

local RoomRenderer = {}

--- Hide blocked doors from map rendering (temporarily clear to 0)
-- @param room The room to process
function RoomRenderer.hide_blocked_doors(room)
    if not room or not room.doors then return end
    for dir, door in pairs(room.doors) do
        if door.sprite == DOOR_BLOCKED_TILE then
            local pos = room:get_door_tile(dir)
            if pos then mset(pos.tx, pos.ty, 0) end
        end
    end
end

--- Restore blocked doors to map for collision detection
-- @param room The room to restore
function RoomRenderer.restore_blocked_doors(room)
    if not room or not room.doors then return end
    for dir, door in pairs(room.doors) do
        if door.sprite == DOOR_BLOCKED_TILE then
            local pos = room:get_door_tile(dir)
            if pos then mset(pos.tx, pos.ty, DOOR_BLOCKED_TILE) end
        end
    end
end

--- Fill adjacent room floors with black to hide them through doors
-- Keeps adjacent room walls visible (autotiled corners, H/V walls)
-- @param room The current room
-- @param excluded_rooms Optional table of rooms to skip (used during transitions)
function RoomRenderer.cover_adjacent_room_floors(room, excluded_rooms)
    if not room or not room.doors then return end

    excluded_rooms = excluded_rooms or {}
    palt(0, false)
    for _, door in pairs(room.doors) do
        local adj_room = DungeonManager.rooms[door.target_gx..","..door.target_gy]
        if adj_room then
            -- Check if this room should be excluded
            local skip = false
            for _, excluded in ipairs(excluded_rooms) do
                if excluded == adj_room then
                    skip = true
                    break
                end
            end

            if not skip then
                -- Cover only the floor (inner bounds), not the walls
                local floor = adj_room:get_inner_bounds()
                rectfill(
                    floor.x1 * GRID_SIZE,
                    floor.y1 * GRID_SIZE,
                    (floor.x2 + 1) * GRID_SIZE - 1,
                    (floor.y2 + 1) * GRID_SIZE - 1,
                    0
                )
            end
        end
    end
    palt()
end

--- Cover everything outside the active rooms with black, then redraw adjacent room walls
-- @param active_rooms Table of rooms that are currently visible (single room or both during transition)
-- @param cam_x Camera X offset
-- @param cam_y Camera Y offset
function RoomRenderer.cover_void_walls(active_rooms, cam_x, cam_y)
    if not active_rooms or #active_rooms == 0 then return end

    -- Calculate combined bounds of all active rooms
    local first_bounds = active_rooms[1]:get_bounds()
    local min_x, min_y = first_bounds.x1, first_bounds.y1
    local max_x, max_y = first_bounds.x2, first_bounds.y2

    for i = 2, #active_rooms do
        local b = active_rooms[i]:get_bounds()
        min_x = min(min_x, b.x1)
        min_y = min(min_y, b.y1)
        max_x = max(max_x, b.x2)
        max_y = max(max_y, b.y2)
    end

    local px1 = min_x * GRID_SIZE
    local py1 = min_y * GRID_SIZE
    local px2 = (max_x + 1) * GRID_SIZE - 1
    local py2 = (max_y + 1) * GRID_SIZE - 1

    -- Screen bounds in world coordinates
    local screen_x1 = cam_x
    local screen_y1 = cam_y
    local screen_x2 = cam_x + SCREEN_WIDTH - 1
    local screen_y2 = cam_y + SCREEN_HEIGHT - 1

    palt(0, false)
    -- Fill all 4 areas outside combined room bounds with black
    -- Left
    if screen_x1 < px1 then
        rectfill(screen_x1, screen_y1, px1 - 1, screen_y2, 0)
    end
    -- Right
    if screen_x2 > px2 then
        rectfill(px2 + 1, screen_y1, screen_x2, screen_y2, 0)
    end
    -- Top (only the part between left and right room edges)
    if screen_y1 < py1 then
        rectfill(max(screen_x1, px1), screen_y1, min(screen_x2, px2), py1 - 1, 0)
    end
    -- Bottom (only the part between left and right room edges)
    if screen_y2 > py2 then
        rectfill(max(screen_x1, px1), py2 + 1, min(screen_x2, px2), screen_y2, 0)
    end
    palt()

    -- Now redraw the wall tiles of visible adjacent rooms (only their perimeter walls)
    RoomRenderer.redraw_adjacent_walls(active_rooms)
end

--- Redraw wall perimeter of neighbor rooms to maintain visual consistency
-- @param active_rooms Table of rooms that are currently visible
function RoomRenderer.redraw_adjacent_walls(active_rooms)
    local checked = {}
    for _, active_room in ipairs(active_rooms) do
        local gx, gy = active_room.grid_x, active_room.grid_y
        for dy = -2, 2 do
            for dx = -2, 2 do
                local neighbor_key = (gx + dx)..","..(gy + dy)
                -- Skip if already checked or is an active room
                if not checked[neighbor_key] then
                    checked[neighbor_key] = true
                    local neighbor = DungeonManager.rooms[neighbor_key]
                    -- Skip if neighbor is one of the active rooms
                    local is_active = false
                    for _, ar in ipairs(active_rooms) do
                        if ar == neighbor then
                            is_active = true
                            break
                        end
                    end

                    if neighbor and not is_active then
                        -- Redraw wall perimeter of this room using map tiles
                        local nb = neighbor:get_bounds()
                        -- Top wall row
                        for tx = nb.x1, nb.x2 do
                            spr(mget(tx, nb.y1), tx * GRID_SIZE, nb.y1 * GRID_SIZE)
                        end
                        -- Bottom wall row
                        for tx = nb.x1, nb.x2 do
                            spr(mget(tx, nb.y2), tx * GRID_SIZE, nb.y2 * GRID_SIZE)
                        end
                        -- Left wall column (excluding corners already drawn)
                        for ty = nb.y1 + 1, nb.y2 - 1 do
                            spr(mget(nb.x1, ty), nb.x1 * GRID_SIZE, ty * GRID_SIZE)
                        end
                        -- Right wall column (excluding corners already drawn)
                        for ty = nb.y1 + 1, nb.y2 - 1 do
                            spr(mget(nb.x2, ty), nb.x2 * GRID_SIZE, ty * GRID_SIZE)
                        end
                    end
                end
            end
        end
    end
end

--- Draw room during a scroll transition (showing both old and new rooms)
-- @param camera_manager The camera manager instance
-- @param cam_x Camera X offset (including shake)
-- @param cam_y Camera Y offset (including shake)
-- @return clip_square The clip bounds for spotlight rendering
function RoomRenderer.draw_scrolling(camera_manager, cam_x, cam_y)
    local clip_square = {x = 0, y = 0, w = SCREEN_WIDTH, h = SCREEN_HEIGHT}
    local old_room = camera_manager.old_room
    local new_room = camera_manager.new_room
    local active_rooms = {old_room, new_room}

    RoomRenderer.hide_blocked_doors(old_room)
    RoomRenderer.hide_blocked_doors(new_room)
    map()

    -- Cover adjacent room floors, excluding both transitioning rooms
    RoomRenderer.cover_adjacent_room_floors(old_room, active_rooms)
    RoomRenderer.cover_adjacent_room_floors(new_room, active_rooms)

    -- Cover void walls, treating both rooms as active
    RoomRenderer.cover_void_walls(active_rooms, cam_x, cam_y)

    RoomRenderer.restore_blocked_doors(old_room)
    RoomRenderer.restore_blocked_doors(new_room)

    return clip_square, old_room, new_room
end

--- Draw room during normal exploration
-- @param current_room The current room to draw
-- @param cam_x Camera X offset (including shake)
-- @param cam_y Camera Y offset (including shake)
-- @return clip_square The clip bounds for spotlight rendering
function RoomRenderer.draw_exploring(current_room, cam_x, cam_y)
    local room_pixels = current_room.pixels
    local clip_square = {
        x = room_pixels.x - cam_x,
        y = room_pixels.y - cam_y,
        w = room_pixels.w,
        h = room_pixels.h
    }
    RoomRenderer.hide_blocked_doors(current_room)
    map()
    RoomRenderer.cover_adjacent_room_floors(current_room)
    RoomRenderer.cover_void_walls({current_room}, cam_x, cam_y)
    RoomRenderer.restore_blocked_doors(current_room)

    return clip_square
end

return RoomRenderer
