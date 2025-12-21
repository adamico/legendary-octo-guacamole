local Systems = require("systems")
local Entities = require("entities")

local Play = SceneManager:addState("Play")

local ROOM_CLIP = {
   x = 7,
   y = 3,
   w = 12,
   h = 11
}

local ROOM_PIXELS = {
   x = ROOM_CLIP.x * GRID_SIZE,
   y = ROOM_CLIP.y * GRID_SIZE,
   w = ROOM_CLIP.w * GRID_SIZE,
   h = ROOM_CLIP.h * GRID_SIZE
}

world = eggs()
player = {}

local function draw_entity(entity)
   local was_flashing = entity.flash_timer and entity.flash_timer > 0
   Systems.Effects.update_flash(entity)
   Systems.drawable(entity)
   -- Reset draw palette after flash (reset_spotlight handles color table each frame)
   if was_flashing then
      pal(0)
   end
end

local function draw_room()
   clip(ROOM_PIXELS.x, ROOM_PIXELS.y, ROOM_PIXELS.w, ROOM_PIXELS.h)
   rectfill(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, 5)
   clip()
end

function Play:enteredState()
   Log.trace("Entered Play scene")
   -- Initialize extended palette colors 32-63 for variants
   Systems.init_extended_palette()
   -- Initialize spotlight color table for lighting effects
   Systems.init_spotlight()
   player = Entities.spawn_player(world, 10 * 16, 4 * 16)

   Systems.Spawner.init_room(player, ROOM_CLIP, 5, 80, {"Skulker", "Shooter"})
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
   draw_room()
   map()
   Systems.reset_spotlight()
   world.sys("spotlight", function(entity) Systems.draw_spotlight(entity, ROOM_PIXELS) end)()

   -- 1. Background Layer: Shadows, Projectiles, Pickups
   world.sys("background,drawable_shadow", function(entity) Systems.draw_shadow_entity(entity, ROOM_PIXELS) end)()
   world.sys("background,drawable", function(entity)
      draw_entity(entity)
   end)()

   -- 2. Middleground Layer: Characters (Y-Sorted)
   Systems.draw_ysorted(world, "middleground,drawable", function(entity)
      draw_entity(entity)
   end)

   -- 3. Global Effects & Debug
   world.sys("palette_swappable", Systems.palette_swappable)()
   Systems.Spawner.draw(ROOM_PIXELS)

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
