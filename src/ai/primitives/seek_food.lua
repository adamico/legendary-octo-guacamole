-- AI Primitive: Seek Food
-- Causes entity to seek towards YolkSplat entities and consume them for health
-- OPTIMIZED: No intermediate table allocation, squared distances

local HitboxUtils = require("src/utils/hitbox_utils")
local GameConstants = require("src/game/game_config")
local FloatingText = require("src/systems/floating_text")

local SeekFood = {}

-- Check if entity is overlapping food
local function check_collision(entity, food)
   local hb1 = HitboxUtils.get_hitbox(entity)
   local hb2 = HitboxUtils.get_hitbox(food)

   return hb1.x < hb2.x + hb2.w and
      hb1.x + hb1.w > hb2.x and
      hb1.y < hb2.y + hb2.h and
      hb1.y + hb1.h > hb2.y
end

--- Update SeekFood behavior
--- OPTIMIZED: Find nearest directly in ECS callback (no table allocation)
--- @param entity Entity - The hungry entity
--- @param world table - ECS world for querying and deleting entities
--- @param range number - Scanning range (default 100)
--- @param heal_amount number - Amount to heal (default 5)
--- @return boolean - Returns true if food was found/pursued/eaten, false otherwise
function SeekFood.update(entity, world, range, heal_amount)
   range = range or 100
   heal_amount = heal_amount or 5

   -- Find nearest YolkSplat directly in callback (avoid table allocation)
   local nearest_food = nil
   local nearest_dist_sq = range * range -- Distance squared
   local ex, ey = entity.x, entity.y

   -- OPTIMIZATION: Find nearest directly in ECS query callback
   world.sys("yolk_splat", function(food)
      local dx = food.x - ex
      local dy = food.y - ey
      local dist_sq = dx * dx + dy * dy

      if dist_sq < nearest_dist_sq then
         nearest_dist_sq = dist_sq
         nearest_food = food
      end
   end)()

   if nearest_food then
      -- Move towards food (need sqrt only for movement direction)
      local dx = nearest_food.x - ex
      local dy = nearest_food.y - ey
      local dist = sqrt(nearest_dist_sq)

      if dist > 0 then
         dx = dx / dist
         dy = dy / dist

         entity.vel_x = dx * (entity.max_speed or 0.5)
         entity.vel_y = dy * (entity.max_speed or 0.5)

         -- Check if reached/eating
         if check_collision(entity, nearest_food) then
            -- Eat it!
            world.del(nearest_food)
            entity.hp = math.min((entity.max_hp or 10), entity.hp + heal_amount)
            -- Spawn heal text or effect
            if FloatingText then
               FloatingText.spawn_heal(entity, heal_amount)
            end
         end
         return true -- Busy eating
      end
   end

   return false -- No food found
end

return SeekFood
