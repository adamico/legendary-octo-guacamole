local Systems = require("systems")
local Entities = require("entities")

local Play = SceneManager:addState("Play")

local ROOM_CLIP = {
   x = 7 * 16,
   y = 16,
   w = 12 * 16,
   h = 11 * 16
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
   clip(ROOM_CLIP.x, ROOM_CLIP.y, ROOM_CLIP.w, ROOM_CLIP.h)
   rectfill(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, 5)
   clip()
end

function Play:enteredState()
   Log.trace("Entered Play scene")
   -- Initialize extended palette colors 32-63 for variants
   Systems.init_extended_palette()
   -- Initialize spotlight color table for lighting effects
   Systems.init_spotlight()
   player = Entities.spawn_player(world, 10 * 16, 2 * 16)

   -- Spawn enemies at random positions far from the player
   local num_enemies = 3
   local min_dist = 80
   local spawned = 0
   for i = 1, 200 do
      if spawned >= num_enemies then break end

      local rx = ROOM_CLIP.x + rnd(ROOM_CLIP.w - 16)
      local ry = ROOM_CLIP.y + rnd(ROOM_CLIP.h - 16)

      local dx = rx - player.x
      local dy = ry - player.y
      if dx * dx + dy * dy > min_dist * min_dist then
         -- Check if the position is not a solid tile
         local tx, ty = flr((rx + 8) / 16), flr((ry + 8) / 16)
         local tile = mget(tx, ty)
         if tile and not fget(tile, SOLID_FLAG) then
            Entities.spawn_enemy(world, rx, ry, "Skulker")
            spawned = spawned + 1
         end
      end
   end
end

function Play:update()
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
   world.sys("spotlight", function(entity) Systems.draw_spotlight(entity, ROOM_CLIP) end)()
   -- Then shadow and player on top
   world.sys("shadow", function(entity) Systems.draw_shadow(entity, ROOM_CLIP) end)()
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
