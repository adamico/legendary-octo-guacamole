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

   -- Spawn test enemies for MVP
   Entities.spawn_enemy(world, 200, 100, "Skulker")
   Entities.spawn_enemy(world, 150, 150, "Skulker")
   Entities.spawn_enemy(world, 250, 120, "Skulker")
end

function Play:update()
   world.sys("controllable", Systems.controllable)()
   world.sys("acceleration", Systems.acceleration)()
   world.sys("collidable,velocity", Systems.resolve_map_collisions)()
   world.sys("velocity", Systems.velocity)()
   world.sys("animatable", Systems.animatable)()
   world.sys("shooter", Systems.shooter)()
   world.sys("sprite", Systems.change_sprite)()
   -- Check entity-entity collisions for specific combinations
   world.sys("enemy", Systems.enemy_ai)()
   world.sys("collidable", Systems.resolve_entity_collisions)()
   world.sys("health", Systems.health_regen)()
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
   -- Draw entities (with flash effects applied)
   world.sys("drawable", function(entity)
      local was_flashing = entity.flash_timer and entity.flash_timer > 0
      Systems.Effects.update_flash(entity)
      Systems.drawable(entity)
      -- Reset draw palette after flash (reset_spotlight handles color table each frame)
      if was_flashing then
         pal(0)
      end
   end)()

   world.sys("health", Systems.draw_health_bar)()
end

function Play:exitedState()
   Log.trace("Exited Play scene")
end

return Play
