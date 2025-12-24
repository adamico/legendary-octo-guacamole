local RoomManager = Class("RoomManager"):include(Stateful)

local Systems = require("systems")
local Collision = require("collision")
local DungeonManager = require("dungeon_manager")

local OPPOSITE_DIR = {
   north = "south",
   south = "north",
   east = "west",
   west = "east"
}

-- State: Exploring
local Exploring = RoomManager:addState("Exploring")

function Exploring:enteredState()
   Log.trace("Entered Exploring state")
   if self.room then
      self:setupRoom()
   end
end

function Exploring:update(world)
   local room = self.room
   local player = self.player

   -- Check room clear
   if room.lifecycle:is("active") then
      local enemy_count = 0
      world.sys("enemy", function(e)
         if not e.dead then enemy_count += 1 end
      end)()

      if enemy_count == 0 then
         room.lifecycle:clear()
         DungeonManager.apply_door_sprites(room)
      end
   end

   -- Update spawner
   Systems.Spawner.update(world, room)

   -- Check for door trigger
   local door_trigger = Collision.check_door_trigger(player, room)

   -- "Edge trigger" logic: Doors only work after you've stepped off them at least once
   if not door_trigger then
      self.is_door_active = true
   end

   -- Trigger transition (only if activated by leaving a previous door)
   if door_trigger and self.is_door_active then
      self.is_door_active = false -- Force stepping off the new door before re-triggering
      self:gotoState("Scrolling", world, player, door_trigger)
   end
end

function Exploring:exitedState()
   Log.trace("Exited Exploring state")
end

function Exploring:drawRooms()
   self.room:draw()
end

-- State: Scrolling
local Scrolling = RoomManager:addState("Scrolling")

function Scrolling:enteredState(world, player, door_dir)
   Log.trace("Entered Scrolling state, direction: "..door_dir)

   self.door_direction = door_dir
   self.scroll_timer = 0
   self.scroll_duration = 30 -- frames (0.5s at 60fps)

   -- Freeze player by removing movement tags (input and physics systems will ignore them)
   world.unt(player, "controllable,velocity,acceleration")
   player.vel_x = 0
   player.vel_y = 0

   -- Calculate camera movement based on actual room dimensions.
   -- We want the rooms to appear adjacent (walls touching) during the scroll.
   -- The offset is calculated so the next room's wall touches the current room's wall.
   local current_room = self.room
   local next_room = DungeonManager.peek_next_room(door_dir)

   -- Anchor everything to the next room's canonical position (0,0 offset)
   -- Place the current room relative to the next room based on the entrance side
   local ox, oy = self:getAlignmentOffset(next_room, current_room, OPPOSITE_DIR[door_dir])

   self.current_room_offset = {x = ox * GRID_SIZE, y = oy * GRID_SIZE}
   self.next_room_offset = {x = 0, y = 0}

   -- Initialize camera offset to start position (current room offset)
   self.camera_offset = self.current_room_offset

   -- Store next room reference for drawing
   self.next_room = next_room

   -- Offset player position to match the current room's offset
   -- This keeps the player visually in the correct room during the scroll
   player.x += self.current_room_offset.x
   player.y += self.current_room_offset.y

   -- Cleanup old room entities
   world.sys("projectile", function(e) world.del(e) end)()
   world.sys("pickup", function(e) world.del(e) end)()
   world.sys("skull", function(e) world.del(e) end)()

   -- Clear map and carve both rooms at their respective offsets
   DungeonManager.clear_map()
   DungeonManager.carve_room(current_room, nil, ox, oy)
   DungeonManager.carve_corridors(current_room, ox, oy)
   DungeonManager.carve_room(next_room)
   DungeonManager.carve_corridors(next_room)
end

function Scrolling:update(world, player)
   self.scroll_timer += 1
   local progress = self.scroll_timer / self.scroll_duration
   progress = min(progress, 1)

   local ease_t = progress < 0.5
      and 2 * progress * progress
      or 1 - ((-2 * progress + 2) ^ 2) / 2

   -- Interpolate camera from current_room_offset towards 0,0
   local d = 1 - ease_t
   self.camera_offset = {
      x = self.current_room_offset.x * d,
      y = self.current_room_offset.y * d
   }

   if progress >= 1 then
      self:gotoState("Settling")
   end
end

function Scrolling:exitedState()
   Log.trace("Exited Scrolling state")
end

function Scrolling:drawRooms()
   local cox, coy = self.current_room_offset.x, self.current_room_offset.y
   self.room:draw(cox, coy)
   self.next_room:draw(0, 0)
end

local Settling = RoomManager:addState("Settling")

function Settling:enteredState()
   Log.trace("Entered Settling state")

   -- 1. Restore player world coordinates (remove temporary scroll offset)
   local ox, oy = self.current_room_offset.x, self.current_room_offset.y
   local px, py = self.player.x - ox, self.player.y - oy

   -- 2. Commit room transition logical state
   local next_room = DungeonManager.enter_door(self.door_direction, true)

   -- 3. Position player in new room
   local spawn_pos = DungeonManager.calculate_spawn_position(self.door_direction, next_room, px, py)
   self.player.x, self.player.y = spawn_pos.x, spawn_pos.y

   -- Update manager room reference
   self.room = next_room

   -- 4. Finalize and resume
   self:finalizeTransition()
   self:gotoState("Exploring")
end

-- RoomManager instance methods
function RoomManager:update(world, player)
   -- Defined so that stateful can delegate to the active state
end

function RoomManager:drawRooms()
   -- Defined so that stateful can delegate to the active state
end

function RoomManager:initialize(world, player)
   self.world = world
   self.player = player
   self.is_door_active = false
   self.room = DungeonManager.current_room
   self.camera_offset = {x = 0, y = 0}

   self:gotoState("Exploring")
end

-- Refactored Helpers --

-- Calculates tile offset to place 'target' room on a specific 'side' of 'ref' room
-- side: "north", "south", "east", "west"
function RoomManager:getAlignmentOffset(ref, target, side)
   local r, t = ref.tiles, target.tiles
   local gap = CORRIDOR_LENGTH
   if side == "north" then return 0, r.y - t.y - t.h - gap end
   if side == "south" then return 0, r.y - t.y + r.h + gap end
   if side == "east" then return r.x - t.x + r.w + gap, 0 end
   if side == "west" then return r.x - t.x - t.w - gap, 0 end
   return 0, 0
end

-- Initialize room contents (enemies, locks, timers)
function RoomManager:setupRoom()
   local room = self.room
   Systems.Spawner.populate(room, self.player)

   -- If enemies assigned and room is populated, trigger enter to lock doors
   if #room.enemy_positions > 0 and room.lifecycle:can("enter") then
      room.lifecycle:enter()
      DungeonManager.apply_door_sprites(room)
   end

   -- Restart skull timer if entering a cleared combat room
   if room.lifecycle:is("cleared") and room.room_type == "combat" then
      room.skull_timer = SKULL_SPAWN_TIMER
      room.skull_spawned = false
   end
end

-- Reset camera, unfreeze player, and clear transition flags
function RoomManager:finalizeTransition()
   self.camera_offset = {x = 0, y = 0}
   self.world.tag(self.player, "controllable,velocity,acceleration")
   self.is_door_active = false
   self.current_room_offset = nil
   self.next_room_offset = nil
end

-- Getter for camera offset (returns WORLD pixel coordinates)
-- If an offset table is provided, calculates total camera pos for that offset
function RoomManager:getCameraOffset(offset)
   local base = DungeonManager.get_base_camera_offset()
   local off = offset or self.camera_offset
   return base.x + off.x, base.y + off.y
end

function RoomManager:isExploring()
   local stack = self:getStateStackDebugInfo()
   return stack and stack[1] == "Exploring"
end

return RoomManager
