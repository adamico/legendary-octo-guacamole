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
local spawn_timer = 60 -- 1 second delay
local enemies_spawned = false
local spawn_positions = {}

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

local function calculate_spawn_positions()
   local is_not_solid = function(tile)
      return tile and not fget(tile, SOLID_FLAG)
   end
   local is_free_space = function(x, y)
      for _, pos in ipairs(spawn_positions) do
         local dx = x - pos.x
         local dy = y - pos.y
         if dx * dx + dy * dy < 16 * 16 then
            return false
         end
      end
      return true
   end
   spawn_positions = {}
   local num_enemies = 5
   local min_dist = 80
   local attempts = 0
   while #spawn_positions < num_enemies and attempts < 200 do
      attempts = attempts + 1
      local rx = ROOM_CLIP.x * GRID_SIZE + rnd(ROOM_CLIP.w * GRID_SIZE - 16)
      local ry = ROOM_CLIP.y * GRID_SIZE + rnd(ROOM_CLIP.h * GRID_SIZE - 16)

      local dx = rx - player.x
      local dy = ry - player.y
      if dx * dx + dy * dy > min_dist * min_dist then
         -- Check if the position is not a solid tile
         local tx, ty = flr((rx + 8) / 16), flr((ry + 8) / 16)
         local tile = mget(tx, ty)
         if is_not_solid(tile) and is_free_space(rx, ry) then
            table.insert(spawn_positions, {x = rx, y = ry})
         end
      end
   end
end

local function spawn_enemies()
   for _, pos in ipairs(spawn_positions) do
      Entities.spawn_enemy(world, pos.x, pos.y, "Skulker")
   end
end

function Play:enteredState()
   Log.trace("Entered Play scene")
   -- Initialize extended palette colors 32-63 for variants
   Systems.init_extended_palette()
   -- Initialize spotlight color table for lighting effects
   Systems.init_spotlight()
   player = Entities.spawn_player(world, 10 * 16, 4 * 16)

   calculate_spawn_positions()
   spawn_timer = 60
   enemies_spawned = false
end

function Play:update()
   if not enemies_spawned then
      spawn_timer -= 1
      if spawn_timer <= 0 then
         spawn_enemies()
         enemies_spawned = true
      end
   end

   world.sys("controllable", Systems.controllable)()
   world.sys("acceleration", Systems.acceleration)()
   world.sys("collidable,velocity", Systems.resolve_map_collisions)()
   world.sys("velocity", Systems.velocity)()
   world.sys("animatable", Systems.update_fsm)()
   world.sys("sprite", Systems.change_sprite)()
   world.sys("animatable", Systems.animate)()
   world.sys("shooter", Systems.shoot_input)()
   world.sys("shooter", Systems.projectile_fire)()
   -- Check entity-entity collisions for specific combinations
   world.sys("enemy", Systems.enemy_ai)()
   world.sys("collidable", Systems.resolve_entity_collisions)()
   world.sys("health", Systems.health_regen)()
   world.sys("player", Systems.invulnerability_tick)()
   world.sys("health", Systems.health_manager)()

   -- Update effects (screenshake)
   Systems.Effects.update_shake()
end

function Play:draw()
   cls(0)
   draw_room()
   map()
   -- Reset spotlight color table (in case flash effects corrupted it)
   Systems.reset_spotlight()
   -- Draw spotlight first (brightens background)
   world.sys("spotlight", function(entity) Systems.draw_spotlight(entity, ROOM_PIXELS) end)()
   -- Then shadow and player on top
   world.sys("shadow", function(entity) Systems.draw_shadow(entity, ROOM_PIXELS) end)()
   -- Draw background entities (projectiles, pickups) behind characters
   world.sys("drawable", function(entity)
      if entity.type == "Projectile" or entity.type == "ProjectilePickup" then
         draw_entity(entity)
      end
   end)()
   world.sys("palette_swappable", Systems.palette_swappable)()
   -- Draw characters (Player, Enemy) and everything else in front
   world.sys("drawable", function(entity)
      if entity.type ~= "Projectile" and entity.type ~= "ProjectilePickup" then
         draw_entity(entity)
      end
   end)()

   -- Draw spawn indicators if timer is still active
   if not enemies_spawned then
      -- Blinking effect: toggle visibility every 8 frames
      if spawn_timer % 15 < 8 then
         clip(ROOM_PIXELS.x, ROOM_PIXELS.y, ROOM_PIXELS.w, ROOM_PIXELS.h)
         for _, pos in ipairs(spawn_positions) do
            spr(207, pos.x, pos.y)
         end
         clip()
      end
   end

   pal()

   world.sys("health", Systems.draw_health_bar)()
   if key("f2") then
      world.sys("collidable", Systems.draw_hitbox)()
   end
end

function Play:exitedState()
   Log.trace("Exited Play scene")
end

return Play
