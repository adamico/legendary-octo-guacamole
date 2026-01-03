-- Bomber system
-- Handles bomb placement on X button press and fuse countdown/explosion

local GameState = require("src/game/game_state")
local GameConstants = require("src/game/game_config")
local Entities = require("src/entities")
local HitboxUtils = require("src/utils/hitbox_utils")
local Particles = require("src/systems/particles")
local Effects = require("src/systems/effects")

local Bomber = {}

-- Bomb placement cooldown (prevent spam)
local BOMB_COOLDOWN = 30 -- Half second

function Bomber.update(world)
   -- Handle player bomb placement
   world.sys("player,controllable", function(player)
      -- Check cooldown
      if player.bomb_cooldown and player.bomb_cooldown > 0 then
         player.bomb_cooldown -= 1
         return
      end

      -- Check if X button pressed and player has bombs (or infinite inventory)
      local input_pressed = btnp(GameConstants.controls.place_bomb)
      local has_bombs = (player.bombs and player.bombs > 0) or GameState.cheats.infinite_inventory

      if input_pressed and has_bombs then
         -- Consume bomb from inventory if not infinite
         if not GameState.cheats.infinite_inventory then
            player.bombs -= 1
         end

         -- Spawn bomb at player's hitbox center
         local hb = HitboxUtils.get_hitbox(player)
         local cx = hb.x + hb.w / 2
         local cy = hb.y + hb.h / 2
         Entities.spawn_bomb(world, cx, cy)

         -- Set cooldown
         player.bomb_cooldown = BOMB_COOLDOWN
      end
   end)()

   -- Handle bomb fuse countdown and explosion
   world.sys("bomb", function(bomb)
      -- Decrement fuse timer
      if bomb.fuse_timer then
         bomb.fuse_timer -= 1

         -- Blinking red flash as bomb is about to explode
         local blink_interval
         if bomb.fuse_timer < 30 then
            blink_interval = 2 -- Fast blinking in last 0.5 seconds
         elseif bomb.fuse_timer < 60 then
            blink_interval = 4 -- Medium blinking
         elseif bomb.fuse_timer < 90 then
            blink_interval = 8 -- Slow blinking when starting to warn
         end

         if blink_interval then
            -- Toggle flash on/off based on frame modulo
            if bomb.fuse_timer % (blink_interval * 2) < blink_interval then
               bomb.flash_timer = 1
               bomb.flash_color = 8 -- Red
            else
               bomb.flash_timer = 0
            end
         end

         if bomb.fuse_timer <= 0 then
            -- Explode! Spawn 3x3 grid of explosions
            local radius = bomb.explosion_radius or 1
            Entities.spawn_explosion_grid(world, bomb.x, bomb.y, radius)

            -- Explosion particles at bomb center
            local cx = bomb.x + (bomb.width or 16) / 2
            local cy = bomb.y + (bomb.height or 16) / 2
            Particles.spawn_burst(cx, cy, "explosion") -- Uses preset count

            -- Strong screen shake
            Effects.screen_shake(6, 8)
            -- Destroy obstacles in explosion area
            Bomber.destroy_obstacles_in_radius(world, bomb.x, bomb.y, radius)

            -- Delete the bomb entity
            world.del(bomb)
         end
      end
   end)()
end

-- Helper: Destroy all obstacles within the explosion radius
-- NOTE: This explicitly excludes chests from destruction
function Bomber.destroy_obstacles_in_radius(world, center_x, center_y, radius)
   world.sys("obstacle", function(obstacle)
      -- Skip chests - bombs should not destroy them
      if obstacle.is_chest then
         return
      end

      -- Check if obstacle is within explosion radius
      local ox = obstacle.x + (obstacle.width or 16) / 2
      local oy = obstacle.y + (obstacle.height or 16) / 2

      local dx = abs(ox - center_x)
      local dy = abs(oy - center_y)

      -- Within grid radius (in pixels)
      local max_dist = (radius + 0.5) * GRID_SIZE

      if dx <= max_dist and dy <= max_dist then
         -- Destroy the obstacle
         if not obstacle.dead then
            obstacle.dead = true
            world.del(obstacle)
         end
      end
   end)()
end

return Bomber
