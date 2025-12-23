local DungeonManager = require("dungeon_manager")
local Entities = require("entities")
local RoomManager = require("room_manager")
local Systems = require("systems")

local SceneManager = require("scene_manager")

local Play = SceneManager:addState("Play")

world = eggs()
local player
local room_manager

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
   room_manager = RoomManager:new(world, player)
end

function Play:update()
   room_manager:update(world, player)

   if room_manager:isExploring() then
      world.sys("controllable", Systems.read_input)()
      world.sys("acceleration", Systems.acceleration)()
      world.sys("map_collidable,velocity", function(e)
         Systems.resolve_map(e, DungeonManager.current_room)
      end)()
      world.sys("velocity", Systems.velocity)()
      world.sys("animatable", Systems.update_fsm)()
      world.sys("sprite", Systems.change_sprite)()
      world.sys("animatable", Systems.animate)()
      world.sys("shooter", Systems.projectile_fire)()
      world.sys("enemy", Systems.enemy_ai)()
      world.sys("collidable", Systems.resolve_entities)()
      world.sys("health", Systems.health_regen)()
      world.sys("player", Systems.invulnerability_tick)()
      world.sys("health", Systems.health_manager)()
      world.sys("shadow_entity", Systems.sync_shadows)()

      Systems.Effects.update_shake()
   end

   if keyp("f3") then
      GameConstants.cheats.godmode = not GameConstants.cheats.godmode
   end
end

function Play:draw()
   cls(0)

   local scroll = room_manager:getCameraOffset()
   local shake = Systems.Effects.get_shake_offset()
   camera(scroll.x + shake.x, scroll.y - 7 + shake.y)

   local room_pixels = DungeonManager.current_room.pixels
   local clip_square = {
      x = room_pixels.x - scroll.x,
      y = room_pixels.y - (scroll.y - 7),
      w = room_pixels.w,
      h = room_pixels.h
   }

   Systems.reset_spotlight()
   room_manager:drawRooms()
   map()
   world.sys("spotlight", function(entity) Systems.draw_spotlight(entity, clip_square) end)()

   -- 1. Background Layer: Shadows, Projectiles, Pickups
   world.sys("background,drawable_shadow",
      function(entity) Systems.draw_shadow_entity(entity, clip_square) end)()
   world.sys("background,drawable", function() Systems.draw_layer(world, "background,drawable", false) end)()

   -- 2. Middleground Layer: Characters (Y-Sorted)
   Systems.draw_layer(world, "middleground,drawable", true)

   -- 3. Global Effects & Debug
   world.sys("palette_swappable", Systems.palette_swappable)()
   Systems.Spawner.draw(DungeonManager.current_room)

   pal()

   -- 4. Foreground Layer: Entity UI (Health Bars, Hitboxes)
   -- These must be drawn while world camera is active to track entities correctly
   world.sys("health", Systems.draw_health_bar)()
   if key("f2") then
      world.sys("collidable", Systems.draw_hitbox)()
   end

   -- Reset camera for global UI (HUD, etc.)
   camera()
end

function Play:exitedState()
   Log.trace("Exited Play scene")
end

return Play
