local Systems = require("systems")
local Entities = require("entities")
local DungeonManager = require("dungeon_manager")

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
   DungeonManager.init()

   local px = DungeonManager.current_room.pixels.x + DungeonManager.current_room.pixels.w / 2
   local py = DungeonManager.current_room.pixels.y + DungeonManager.current_room.pixels.h / 2
   player = Entities.spawn_player(world, px, py)

   -- Initial Camera
   camera(DungeonManager.current_room.grid_x * SCREEN_WIDTH, DungeonManager.current_room.grid_y * SCREEN_HEIGHT)

   DungeonManager.populate_enemies(DungeonManager.current_room, player, nil, 80, {"Skulker", "Shooter"})
end

function Play:update()
   -- Door Collision Check
   local door_dir = DungeonManager.check_door_collision(player.x, player.y)
   if door_dir then
      -- Cleanup current room entities (enemies, projectiles) before transition
      -- This is crucial for single-screen spawning where rooms overlap in world-space
      world.sys("projectile", function(e) world.del(e) end)()
      world.sys("pickup", function(e) world.del(e) end)()

      local next_room = DungeonManager.enter_door(door_dir)
      if next_room then
         -- Teleport player to opposite side
         local target_x, target_y = player.x, player.y
         local inset = 16 -- 1 tile inside

         if door_dir == "east" then
            target_x = next_room.pixels.x + 4 -- Close to left wall
            target_y = next_room.pixels.y + next_room.pixels.h / 2
         elseif door_dir == "west" then
            target_x = next_room.pixels.x + next_room.pixels.w - 20
            target_y = next_room.pixels.y + next_room.pixels.h / 2
         elseif door_dir == "north" then
            target_x = next_room.pixels.x + next_room.pixels.w / 2
            target_y = next_room.pixels.y + next_room.pixels.h - 20
         elseif door_dir == "south" then
            target_x = next_room.pixels.x + next_room.pixels.w / 2
            target_y = next_room.pixels.y + 4
         end

         player.x = target_x
         player.y = target_y

         DungeonManager.populate_enemies(next_room, player, nil, 80, {"Skulker", "Shooter"})
      end
   end

   -- Check for Room Clear (Unlock)
   if DungeonManager.current_room and DungeonManager.current_room.is_locked then
      if DungeonManager.current_room.spawned then
         local enemy_count = 0
         -- specific query for active enemies
         world.sys("enemy", function(e)
            if not e.dead then enemy_count = enemy_count + 1 end
         end)()

         if enemy_count == 0 then
            DungeonManager.unlock_room(DungeonManager.current_room)
         end
      end
   end

   Systems.Spawner.update(world, DungeonManager.current_room)

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
   -- Ensure camera is centered
   camera(0, 0)

   DungeonManager.draw()

   -- Draw the map section for the current room
   map()

   Systems.reset_spotlight()
   world.sys("spotlight", function(entity) Systems.draw_spotlight(entity, DungeonManager.current_room.pixels) end)()

   -- 1. Background Layer: Shadows, Projectiles, Pickups
   world.sys("background,drawable_shadow",
      function(entity) Systems.draw_shadow_entity(entity, DungeonManager.current_room.pixels) end)()
   world.sys("background,drawable", function(entity)
      draw_entity(entity)
   end)()

   -- 2. Middleground Layer: Characters (Y-Sorted)
   Systems.draw_ysorted(world, "middleground,drawable", function(entity)
      draw_entity(entity)
   end)

   -- 3. Global Effects & Debug
   world.sys("palette_swappable", Systems.palette_swappable)()
   Systems.Spawner.draw(DungeonManager.current_room)

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
