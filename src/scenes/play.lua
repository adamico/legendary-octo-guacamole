local DungeonManager = require("dungeon_manager")
local CameraManager = require("camera_manager")
local RoomRenderer = require("room_renderer")
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
      DungeonManager.setup_room(current_room, player, world)
      world.sys("projectile", function(e) world.del(e) end)()
      world.sys("pickup", function(e) world.del(e) end)()
      world.sys("skull", function(e) world.del(e) end)()
   end

   -- Setup initial room
   DungeonManager.setup_room(current_room, player, world)
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
   DungeonManager.check_room_clear(current_room, world)

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

function Play:draw()
   cls(0)

   local sx, sy = camera_manager:get_offset()
   local shake = Systems.Effects.get_shake_offset()
   local cam_x = sx + shake.x
   local cam_y = sy + shake.y
   camera(cam_x, cam_y)

   local clip_square
   if camera_manager:is_scrolling() then
      local old_room = camera_manager.old_room
      local new_room = camera_manager.new_room

      clip_square = RoomRenderer.draw_scrolling(camera_manager, cam_x, cam_y)
      Systems.draw_doors(old_room)
      Systems.draw_doors(new_room)
   else
      clip_square = RoomRenderer.draw_exploring(current_room, cam_x, cam_y)
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

return Play
