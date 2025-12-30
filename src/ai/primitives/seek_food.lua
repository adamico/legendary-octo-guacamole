-- AI Primitive: Seek Food
-- Causes entity to seek towards YolkSplat entities and consume them for health

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
--- @param entity Entity - The hungry entity
--- @param world table - ECS world for querying and deleting entities
--- @param range number - Scanning range (default 100)
--- @param heal_amount number - Amount to heal (default 5)
--- @return boolean - Returns true if food was found/pursued/eaten, false otherwise
function SeekFood.update(entity, world, range, heal_amount)
   range = range or 100
   heal_amount = heal_amount or 5

   -- Find nearest YolkSplat
   local nearest_food = nil
   local nearest_dist = range * range -- Distance squared

   -- Iterate all entities with yolk_splat tag
   -- Using world filter if possible, or naive iteration if not efficiently indexed
   -- Efficient way: ECS query
   local candidates = {}
   world.sys("yolk_splat", function(food)
      table.insert(candidates, food)
   end)()

   local ex, ey = entity.x, entity.y

   for _, food in ipairs(candidates) do
      local dx = food.x - ex
      local dy = food.y - ey
      local dist_sq = dx * dx + dy * dy

      if dist_sq < nearest_dist then
         nearest_dist = dist_sq
         nearest_food = food
      end
   end

   if nearest_food then
      -- Move towards food
      local dx = nearest_food.x - ex
      local dy = nearest_food.y - ey
      local dist = sqrt(nearest_dist)

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
               FloatingText.spawn_at_entity(entity, heal_amount, "heal")
            end
         end
         return true -- Busy eating
      end
   end

   return false -- No food found
end

return SeekFood
