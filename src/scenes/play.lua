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
      if door.sprite == SPRITE_DOOR_BLOCKED then
         local pos = room:get_door_tile(dir)
         if pos then mset(pos.tx, pos.ty, 0) end
      end
   end
end

-- Restore blocked doors to map for collision detection
local function restore_blocked_doors(room)
   if not room or not room.doors then return end
   for dir, door in pairs(room.doors) do
      if door.sprite == SPRITE_DOOR_BLOCKED then
         local pos = room:get_door_tile(dir)
         if pos then mset(pos.tx, pos.ty, SPRITE_DOOR_BLOCKED) end
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
      camera_manager.old_room:draw()
      camera_manager.new_room:draw()
      hide_blocked_doors(camera_manager.old_room)
      hide_blocked_doors(camera_manager.new_room)
      map()
      restore_blocked_doors(camera_manager.old_room)
      restore_blocked_doors(camera_manager.new_room)
   else
      local room_pixels = current_room.pixels
      clip_square = {
         x = room_pixels.x - cam_x,
         y = room_pixels.y - cam_y,
         w = room_pixels.w,
         h = room_pixels.h
      }
      current_room:draw()
      hide_blocked_doors(current_room)
      map()
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
      print(timer_str, 8, 8, 7)
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
