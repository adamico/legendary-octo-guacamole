-- Bomber system
-- Handles bomb placement on X button press and fuse countdown/explosion

local GameState = require("src/game/game_state")
local GameConstants = require("src/game/game_config")
local Entities = require("src/entities")
local EntityProxy = require("src/utils/entity_proxy")

local Bomber = {}

-- Bomb placement cooldown (prevent spam)
local BOMB_COOLDOWN = 30 -- Half second

function Bomber.update(world)
   -- Handle player bomb placement
   world:query({"player", "controllable", "position", "inventory"}, function(ids, pos, inv)
      for i = ids.first, ids.last do
         local player_id = ids[i]
         local player = EntityProxy.new(world, player_id)

         -- Check cooldown (using transient field on proxy)
         if player.bomb_cooldown and player.bomb_cooldown > 0 then
            player.bomb_cooldown -= 1
         else
            -- Check if X button pressed and player has bombs (or infinite inventory)
            local input_pressed = btnp(GameConstants.controls.place_bomb)
            local has_bombs = (inv.bombs[i] > 0) or GameState.cheats.infinite_inventory

            if input_pressed and has_bombs then
               -- Consume bomb from inventory if not infinite
               if not GameState.cheats.infinite_inventory then
                  inv.bombs[i] -= 1
               end

               -- Spawn bomb at player's center position (tile-aligned)
               local cx = pos.x[i] + 8 -- Center offset
               local cy = pos.y[i] + 8
               Entities.spawn_bomb(world, cx, cy)

               -- Set cooldown
               player.bomb_cooldown = BOMB_COOLDOWN
            end
         end
      end
   end)

   -- Handle bomb fuse countdown and explosion
   world:query({"bomb", "position", "timers"}, function(ids, pos, timers)
      for i = ids.first, ids.last do
         local bomb_id = ids[i]
         local fuse_timer = timers.lifespan[i]

         if fuse_timer then
            timers.lifespan[i] = fuse_timer - 1

            if timers.lifespan[i] <= 0 then
               -- Explode! Spawn 3x3 grid of explosions
               local bomb = EntityProxy.new(world, bomb_id)
               local radius = bomb.explosion_radius or 1
               Entities.spawn_explosion_grid(world, pos.x[i], pos.y[i], radius)

               -- Destroy obstacles in explosion area
               Bomber.destroy_obstacles_in_radius(world, pos.x[i], pos.y[i], radius)

               -- Delete the bomb entity
               world:remove_entity(bomb_id)
            end
         end
      end
   end)
end

-- Helper: Destroy all obstacles within the explosion radius
-- NOTE: This explicitly excludes chests from destruction
function Bomber.destroy_obstacles_in_radius(world, center_x, center_y, radius)
   local to_remove = {}

   world:query({"obstacle", "position", "size?"}, function(ids, pos, size)
      for i = ids.first, ids.last do
         local obstacle_id = ids[i]
         local obstacle = EntityProxy.new(world, obstacle_id)

         -- Skip chests - bombs should not destroy them
         if obstacle.is_chest then
            goto continue
         end

         -- Check if obstacle is within explosion radius
         local w = size and size.width[i] or 16
         local h = size and size.height[i] or 16
         local ox = pos.x[i] + w / 2
         local oy = pos.y[i] + h / 2

         local dx = abs(ox - center_x)
         local dy = abs(oy - center_y)

         -- Within grid radius (in pixels)
         local max_dist = (radius + 0.5) * GRID_SIZE

         if dx <= max_dist and dy <= max_dist then
            -- Mark for removal (can't remove during query)
            add(to_remove, obstacle_id)
         end

         ::continue::
      end
   end)

   -- Remove marked obstacles
   for _, id in ipairs(to_remove) do
      world:remove_entity(id)
   end
end

return Bomber
