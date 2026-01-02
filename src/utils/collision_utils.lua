-- Collision Utilities
-- Low-level collision detection primitives (stateless)
-- Extracted to avoid circular dependencies between Collision System and Handlers

local CollisionUtils = {}

local HitboxUtils = require("src/utils/hitbox_utils")

local get_hitbox = HitboxUtils.get_hitbox

-- Constants (Must match global config if not passed)
local GRID_SIZE = 16
local TILE_EDGE_TOLERANCE = 1
local SOLID_FLAG = 0
local FEATURE_FLAG_PIT = 4 -- Check globals or pass explicitly if needed

--- Helper: Iterate over tiles overlapping a hitbox
--- @param hb Hitbox
--- @param callback function(tx, ty, tile)
--- @return nil|number, nil|number, nil|number
function CollisionUtils.for_each_tile(hb, callback)
   local x1 = flr(hb.x / GRID_SIZE)
   local y1 = flr(hb.y / GRID_SIZE)
   local x2 = flr((hb.x + hb.w - TILE_EDGE_TOLERANCE) / GRID_SIZE)
   local y2 = flr((hb.y + hb.h - TILE_EDGE_TOLERANCE) / GRID_SIZE)

   for tx = x1, x2 do
      for ty = y1, y2 do
         local tile = mget(tx, ty)
         local r1, r2, r3 = callback(tx, ty, tile)
         if r1 ~= nil then return r1, r2, r3 end
      end
   end
   return nil, nil, nil
end

--- Find solid tile with entity-aware logic
---
--- @param x number
--- @param y number
--- @param w number
--- @param h number
--- @param entity Entity
--- @returns nil|number, nil|number, nil|number
function CollisionUtils.find_solid_tile(x, y, w, h, entity)
   local stx, sty, stile = CollisionUtils.for_each_tile({x = x, y = y, w = w, h = h}, function(tx, ty, tile)
      if tile and fget(tile, SOLID_FLAG) then
         -- All projectiles (player and enemy) can fly over pits
         if fget(tile, FEATURE_FLAG_PIT) and entity and
            (entity.type == "Projectile" or entity.type == "EnemyProjectile") then
            return nil     -- Projectiles ignore pits
         end
         return tx, ty, tile
      end
   end)

   return stx, sty, stile
end

--- Check if an area contains a solid tile
---
--- @param x number
--- @param y number
--- @param w number
--- @param h number
--- @param entity Entity
--- @return boolean
function CollisionUtils.is_solid(x, y, w, h, entity)
   return CollisionUtils.find_solid_tile(x, y, w, h, entity) ~= nil
end

return CollisionUtils
