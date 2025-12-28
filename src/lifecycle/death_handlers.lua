-- Entity death behavior registry
local Entities = require("src/entities")
local GameConstants = require("src/game/game_config")
local Events = require("src/game/events")

local DeathHandlers = {}

-- Loot table for enemies (weights must sum to 1.0)
local ENEMY_LOOT = {
   {type = "HealthPickup", weight = 0.50},
   {type = "Coin",         weight = 0.30},
   {type = "Bomb",         weight = 0.15},
   {type = "Key",          weight = 0.05},
}

-- Helper: Pick a random loot type from weighted table
local function pick_loot(loot_table)
   local roll = rnd()
   local cumulative = 0
   for _, entry in ipairs(loot_table) do
      cumulative = cumulative + entry.weight
      if roll < cumulative then
         return entry.type
      end
   end
   return loot_table[#loot_table].type
end

DeathHandlers.Player = function(world, entity)
   Log.trace("Player died!")
   Events.emit(Events.GAME_OVER)
end

DeathHandlers.Enemy = function(world, entity)
   local drop_chance = entity.drop_chance or 1.0
   local loot_rolls = entity.loot_rolls or 1
   local cx = entity.x + (entity.width or 16) / 2
   local cy = entity.y + (entity.height or 16) / 2

   for i = 1, loot_rolls do
      if rnd() < drop_chance then
         local loot_type
         if entity.use_diverse_loot then
            loot_type = pick_loot(ENEMY_LOOT)
         else
            loot_type = "HealthPickup"
         end
         -- Offset each item slightly to reduce overlap
         local offset_x = (i - 1) * 8 - (loot_rolls - 1) * 4
         local offset_y = (rnd() - 0.5) * 4
         Entities.spawn_pickup(world, cx + offset_x, cy + offset_y, loot_type)
      end
   end
   world.del(entity)
end

DeathHandlers.default = function(world, entity)
   Log.trace("Entity died: "..(entity.type or "Unknown"))
   world.del(entity)
end

return DeathHandlers
