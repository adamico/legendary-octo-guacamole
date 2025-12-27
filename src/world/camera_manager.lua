local GameConstants = require("src/game/game_config")
local Events = require("src/utils/events")
local CameraManager = Class("CameraManager")
CameraManager:include(Stateful)

local DungeonManager = require("src/world/dungeon_manager")

-- Camera manager responsible for following the player and handling transitions
function CameraManager:initialize(player)
    self.player = player
    self.x = 0
    self.y = 0
    self.current_room = nil
    self:gotoState("Following")
end

-- Base update (empty, will be handled by states)
function CameraManager:update()
end

-- FOLLOWING STATE: Normal camera behavior
local Following = CameraManager:addState("Following")

function Following:update()
    if not self.player or not self.current_room then return end

    -- Calculate ideal camera position (center on player)
    local ideal_x = self.player.x - SCREEN_WIDTH / 2
    local ideal_y = self.player.y - SCREEN_HEIGHT / 2

    -- Get room bounds in pixels
    local room_px = self.current_room.pixels

    -- Clamp camera to room boundaries
    -- If room is smaller than screen, center on room
    local cam_x, cam_y

    if room_px.w >= SCREEN_WIDTH then
        -- Room wider than screen: clamp within room
        cam_x = mid(room_px.x, ideal_x, room_px.x + room_px.w - SCREEN_WIDTH)
    else
        -- Room narrower than screen: center on room
        cam_x = room_px.x - (SCREEN_WIDTH - room_px.w) / 2
    end

    if room_px.h >= SCREEN_HEIGHT then
        -- Room taller than screen: clamp within room
        cam_y = mid(room_px.y, ideal_y, room_px.y + room_px.h - SCREEN_HEIGHT)
    else
        -- Room shorter than screen: center on room
        cam_y = room_px.y - (SCREEN_HEIGHT - room_px.h) / 2
    end

    self.x = cam_x
    self.y = cam_y
end

-- SCROLLING STATE: Interpolate between rooms
local Scrolling = CameraManager:addState("Scrolling")

function Scrolling:enteredState(new_room, dir_gx, dir_gy)
    self.old_room = self.current_room
    self.new_room = new_room
    self.dir_gx = dir_gx
    self.dir_gy = dir_gy
    self.timer = 0
    self.duration = 30 -- Faster transition (45 was a bit long)

    -- Trigger transition events via pub/sub (spawns enemies, clears entities)
    Events.emit(Events.ROOM_TRANSITION, new_room)

    self.start_x = self.x
    self.start_y = self.y

    -- Target camera position centering on new room
    local new_px = new_room.pixels
    if new_px.w >= SCREEN_WIDTH then
        -- Ideal X would be centered on player, but for now we clamp to the new room walls
        self.target_x = mid(new_px.x, self.player.x - SCREEN_WIDTH / 2, new_px.x + new_px.w - SCREEN_WIDTH)
    else
        self.target_x = new_px.x - (SCREEN_WIDTH - new_px.w) / 2
    end

    if new_px.h >= SCREEN_HEIGHT then
        self.target_y = mid(new_px.y, self.player.y - SCREEN_HEIGHT / 2, new_px.y + new_px.h - SCREEN_HEIGHT)
    else
        self.target_y = new_px.y - (SCREEN_HEIGHT - new_px.h) / 2
    end
end

function Scrolling:update()
    self.timer = self.timer + 1
    local t = self.timer / self.duration

    -- Smoothstep interpolation
    t = 3 * t * t - 2 * t * t * t

    self.x = self.start_x + (self.target_x - self.start_x) * t
    self.y = self.start_y + (self.target_y - self.start_y) * t

    -- Lock player movement while scrolling
    if self.player then
        self.player.vel_x = 0
        self.player.vel_y = 0
    end

    if self.timer >= self.duration then
        self:set_room(self.new_room)
        self:gotoState("Following")
    end
end

-- Get camera offset for use with camera() function
function CameraManager:get_offset()
    return self.x, self.y
end

-- Handle transition trigger - detect direction and lookup adjacent room
function CameraManager:on_trigger(px, py)
    -- Determine direction based on player position relative to room center
    local room = self.current_room
    local room_cx = room.pixels.x + room.pixels.w / 2
    local room_cy = room.pixels.y + room.pixels.h / 2

    local dx = px - room_cx
    local dy = py - room_cy

    -- Determine primary direction (use larger delta)
    local dir_gx, dir_gy = 0, 0
    if abs(dx) > abs(dy) then
        dir_gx = dx > 0 and 1 or -1
    else
        dir_gy = dy > 0 and 1 or -1
    end

    -- Calculate target grid position
    local target_gx = room.grid_x + dir_gx
    local target_gy = room.grid_y + dir_gy
    local key = target_gx..","..target_gy

    local new_room = DungeonManager.rooms[key]

    if new_room then
        -- Reposition player to entry point (opposite side of new room)
        -- We do this BEFORE the scroll starts so they are in the right spot
        local new_px = new_room.pixels
        local margin = 24 -- Pixels from wall

        local p_w = GameConstants.Player.width or 16
        local p_h = GameConstants.Player.height or 16

        if dir_gx == 1 then
            -- Entered from west, position at left side (preserve Y)
            self.player.x = new_px.x + margin
        elseif dir_gx == -1 then
            -- Entered from east, position at right side (preserve Y)
            self.player.x = new_px.x + new_px.w - margin - p_w
        elseif dir_gy == 1 then
            -- Entered from north, position at top (preserve X)
            self.player.y = new_px.y + margin
        elseif dir_gy == -1 then
            -- Entered from south, position at bottom (preserve X)
            self.player.y = new_px.y + new_px.h - margin - p_h
        end

        self:gotoState("Scrolling", new_room, dir_gx, dir_gy)
        return new_room
    end
    return nil
end

-- Set the current room for camera bounds
function CameraManager:set_room(room)
    self.current_room = room
    DungeonManager.current_room = room
    DungeonManager.current_grid_x = room.grid_x
    DungeonManager.current_grid_y = room.grid_y
end

function CameraManager:is_scrolling()
    local states = self:getStateStackDebugInfo()
    return states[1] == "Scrolling"
end

return CameraManager
