local DungeonManager = require("dungeon_manager")
local Entities = require("entities")
local RoomManager = require("room_manager")
local Systems = require("systems")

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
   -- Room State Management (delegates to current state's update)
   room_manager:update(world, player)

   -- Gameplay Systems (only if exploring)
   if room_manager:isExploring() then
      world.sys("controllable", Systems.controllable)()
      world.sys("acceleration", Systems.acceleration)()
      world.sys("collidable,velocity", function(e)
         Systems.resolve_map_collisions(e, DungeonManager.current_room)
      end)()
      world.sys("velocity", Systems.velocity)()
      world.sys("animatable", Systems.update_fsm)()
      world.sys("sprite", Systems.change_sprite)()
      world.sys("animatable", Systems.animate)()
      world.sys("shooter", Systems.shoot_input)()
      world.sys("shooter", Systems.projectile_fire)()
      world.sys("enemy", Systems.enemy_ai)()
      world.sys("collidable", Systems.resolve_entity_collisions)()
      world.sys("health", Systems.health_regen)()
      world.sys("player", Systems.invulnerability_tick)()
      world.sys("health", Systems.health_manager)()
      world.sys("shadow_entity", Systems.sync_shadows)()

      Systems.Effects.update_shake()
   end
end

function Play:draw()
   cls(0)

   local scroll = room_manager:getCameraOffset()
   camera(scroll.x, scroll.y - 7)

   Systems.reset_spotlight()
   room_manager:drawRooms()
   map()
   world.sys("spotlight", function(entity) Systems.draw_spotlight(entity, DungeonManager.current_room.pixels) end)()

   -- 1. Background Layer: Shadows, Projectiles, Pickups
   world.sys("background,drawable_shadow",
      function(entity) Systems.draw_shadow_entity(entity, DungeonManager.current_room.pixels) end)()
   world.sys("background,drawable", Systems.draw_entity_with_flash)()

   -- 2. Middleground Layer: Characters (Y-Sorted)
   Systems.draw_ysorted(world, "middleground,drawable", Systems.draw_entity_with_flash)

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
