local Systems = require("systems")
local Entities = require("entities")
local RoomManager = require("room_manager")

local Play = SceneManager:addState("Play")

world = eggs()
player = {}

-- TODO: Move this to a system
local function draw_entity(entity)
   local was_flashing = entity.flash_timer and entity.flash_timer > 0
   Systems.Effects.update_flash(entity)
   Systems.drawable(entity)
   if was_flashing then
      pal(0)
   end
end

function Play:enteredState()
   Log.trace("Entered Play scene")
   Systems.init_extended_palette()
   Systems.init_spotlight()
   RoomManager.init()
   player = Entities.spawn_player(world, 10 * 16, 4 * 16)

   Systems.Spawner.init_room(player, RoomManager.current_room.pixels, 5, 80, {"Skulker", "Shooter"})
end

function Play:update()
   Systems.Spawner.update(world)

   world.sys("controllable", Systems.controllable)()
   world.sys("acceleration", Systems.acceleration)()
   world.sys("collidable,velocity", Systems.resolve_map_collisions)()
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

function Play:draw()
   cls(0)
   RoomManager.draw()
   map()
   Systems.reset_spotlight()
   world.sys("spotlight", function(entity) Systems.draw_spotlight(entity, RoomManager.current_room.pixels) end)()

   -- 1. Background Layer: Shadows, Projectiles, Pickups
   world.sys("background,drawable_shadow",
      function(entity) Systems.draw_shadow_entity(entity, RoomManager.current_room.pixels) end)()
   world.sys("background,drawable", function(entity)
      draw_entity(entity)
   end)()

   -- 2. Middleground Layer: Characters (Y-Sorted)
   Systems.draw_ysorted(world, "middleground,drawable", function(entity)
      draw_entity(entity)
   end)

   -- 3. Global Effects & Debug
   world.sys("palette_swappable", Systems.palette_swappable)()
   Systems.Spawner.draw(RoomManager.current_room.pixels)

   pal()

   -- 4. Foreground Layer: UI/Health Bars
   world.sys("health", Systems.draw_health_bar)()
   if key("f2") then
      world.sys("collidable", Systems.draw_hitbox)()
   end
end

function Play:exitedState()
   Log.trace("Exited Play scene")
end

return Play
