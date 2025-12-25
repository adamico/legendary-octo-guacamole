local DungeonManager = require("dungeon_manager")
local CameraManager = require("camera_manager")
local Entities = require("entities")
local Systems = require("systems")
local Emotions = require("emotions")

local SceneManager = require("scene_manager")

local Play = SceneManager:addState("Play")

world = eggs()
local player
local camera_manager
local current_room

function Play:enteredState()
   Log.trace("Entered Play scene")
   Systems.init_extended_palette()
   Systems.init_spotlight()
   DungeonManager.init()

   -- Spawn player at center of start room (World Pixels)
   local room = DungeonManager.current_room
   local px = room.pixels.x + room.pixels.w / 2
   local py = room.pixels.y + room.pixels.h / 2
   player = Entities.spawn_player(world, px, py)

   -- Initialize camera
   camera_manager = CameraManager:new(player)
   current_room = room
   camera_manager:set_room(current_room)

   -- Define transition behavior
   camera_manager.on_transition = function(new_room)
      current_room = new_room
      setupRoom(current_room, player)
      world.sys("projectile", function(e) world.del(e) end)()
      world.sys("pickup", function(e) world.del(e) end)()
      world.sys("skull", function(e) world.del(e) end)()
   end

   -- Setup initial room
   setupRoom(current_room, player)
end

function Play:update()
   -- Update camera
   camera_manager:update()

   -- If scrolling, skip all gameplay systems
   if camera_manager:is_scrolling() then
      return
   end

   -- Update spawner
   Systems.Spawner.update(world, current_room)

   -- Check room clear
   if current_room.lifecycle:is("active") then
      local enemy_count = 0
      current_room.combat_timer += 1
      world.sys("enemy", function(e)
         if not e.dead then enemy_count += 1 end
      end)()

      if enemy_count == 0 then
         current_room.lifecycle:clear()
         DungeonManager.apply_door_sprites(current_room)
      end
   end

   -- Game systems
   world.sys("controllable", Systems.read_input)()
   world.sys("acceleration", Systems.acceleration)()
   world.sys("map_collidable,velocity", function(e)
      Systems.resolve_map(e, current_room, camera_manager)
   end)()
   world.sys("velocity", Systems.velocity)()
   world.sys("animatable", Systems.update_fsm)()
   world.sys("sprite", Systems.change_sprite)()
   world.sys("animatable", Systems.animate)()
   world.sys("shooter", Systems.projectile_fire)()
   world.sys("enemy", Systems.ai)()
   Emotions.update(world)
   world.sys("collidable", Systems.resolve_entities)()
   world.sys("health", Systems.health_regen)()
   world.sys("player", Systems.invulnerability_tick)()
   world.sys("health", Systems.health_manager)()
   world.sys("shadow_entity", Systems.sync_shadows)()

   Systems.Effects.update_shake()

   if keyp("f3") then
      GameConstants.cheats.godmode = not GameConstants.cheats.godmode
   end
end

-- Hide blocked doors from map rendering (temporarily clear to 0)
local function hide_blocked_doors(room)
   if not room or not room.doors then return end
   for dir, door in pairs(room.doors) do
      if door.sprite == DOOR_BLOCKED_TILE then
         local pos = room:get_door_tile(dir)
         if pos then mset(pos.tx, pos.ty, 0) end
      end
   end
end

-- Restore blocked doors to map for collision detection
local function restore_blocked_doors(room)
   if not room or not room.doors then return end
   for dir, door in pairs(room.doors) do
      if door.sprite == DOOR_BLOCKED_TILE then
         local pos = room:get_door_tile(dir)
         if pos then mset(pos.tx, pos.ty, DOOR_BLOCKED_TILE) end
      end
   end
end

-- Fill adjacent room floors with black to hide them through doors
-- Keeps adjacent room walls visible (autotiled corners, H/V walls)
-- excluded_rooms: optional table of rooms to skip (used during transitions)
local function cover_adjacent_room_floors(room, excluded_rooms)
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

-- Cover everything outside the active rooms with black, then redraw adjacent room walls
-- active_rooms: table of rooms that are currently visible (single room or both during transition)
local function cover_void_walls(active_rooms, cam_x, cam_y)
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
   -- Check rooms near all active rooms
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

function Play:draw()
   cls(0)

   local sx, sy = camera_manager:get_offset()
   local shake = Systems.Effects.get_shake_offset()
   local cam_x = sx + shake.x
   local cam_y = sy + shake.y
   camera(cam_x, cam_y)

   local clip_square
   if camera_manager:is_scrolling() then
      clip_square = {x = 0, y = 0, w = SCREEN_WIDTH, h = SCREEN_HEIGHT}
      local old_room = camera_manager.old_room
      local new_room = camera_manager.new_room
      local active_rooms = {old_room, new_room}

      hide_blocked_doors(old_room)
      hide_blocked_doors(new_room)
      map()

      -- Cover adjacent room floors, excluding both transitioning rooms
      cover_adjacent_room_floors(old_room, active_rooms)
      cover_adjacent_room_floors(new_room, active_rooms)

      -- Cover void walls, treating both rooms as active
      cover_void_walls(active_rooms, cam_x, cam_y)

      restore_blocked_doors(old_room)
      restore_blocked_doors(new_room)
      Systems.draw_doors(old_room)
      Systems.draw_doors(new_room)
   else
      local room_pixels = current_room.pixels
      clip_square = {
         x = room_pixels.x - cam_x,
         y = room_pixels.y - cam_y,
         w = room_pixels.w,
         h = room_pixels.h
      }
      hide_blocked_doors(current_room)
      map()
      cover_adjacent_room_floors(current_room)
      cover_void_walls({current_room}, cam_x, cam_y)
      restore_blocked_doors(current_room)
      Systems.draw_doors(current_room)
   end

   Systems.reset_spotlight()
   world.sys("spotlight", function(entity) Systems.draw_spotlight(entity, clip_square) end)()

   -- 1. Background Layer: Shadows, Projectiles, Pickups
   world.sys("background,drawable_shadow",
      function(entity) Systems.draw_shadow_entity(entity, clip_square) end)()
   world.sys("background,drawable", function() Systems.draw_layer(world, "background,drawable", false) end)()

   -- 2. Middleground Layer: Characters (Y-Sorted)
   Systems.draw_layer(world, "middleground,drawable", true)
   Emotions.draw(world)

   -- 3. Global Effects & Debug
   world.sys("palette_swappable", Systems.palette_swappable)()
   Systems.Spawner.draw(current_room)

   pal()

   -- 4. Foreground Layer: Entity UI (Health Bars, Hitboxes)
   world.sys("health", Systems.draw_health_bar)()
   if key("f2") then
      world.sys("collidable", Systems.draw_hitbox)()
   end

   -- Reset camera for global UI
   camera()

   -- draw combat timer
   if current_room.combat_timer and current_room.combat_timer >= 0 then
      local timer = current_room.combat_timer
      local minutes = math.floor(timer / 60)
      local seconds = timer % 60
      local timer_str = string.format("%02d:%02d", minutes, seconds)
      print(timer_str, 10, 10, 8)
   end
end

function Play:exitedState()
   Log.trace("Exited Play scene")
end

-- Helper: Setup a room upon entry
function setupRoom(room, player)
   Systems.Spawner.populate(room, player)

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

return Play
