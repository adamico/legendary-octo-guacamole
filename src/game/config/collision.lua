-- Collision configuration: layers, masks, entity mappings

local CollisionLayers = {
   PLAYER = 1,            -- 0b000001
   ENEMY = 2,             -- 0b000010
   PLAYER_PROJECTILE = 4, -- 0b000100
   ENEMY_PROJECTILE = 8,  -- 0b001000
   PICKUP = 16,           -- 0b010000
   WORLD = 32,            -- 0b100000
   OBSTACLE = 64,         -- 0b1000000
   EXPLOSION = 128,       -- 0b10000000
   MINION = 256,          -- 0b100000000 (friendly minions - don't collide with enemies)
}

-- Shorthand aliases for readability
local L = CollisionLayers

-- What each layer can collide with (bitmask)
local CollisionMasks = {
   [L.PLAYER]            = L.ENEMY + L.ENEMY_PROJECTILE + L.PICKUP + L.WORLD + L.OBSTACLE + L.EXPLOSION,
   [L.ENEMY]             = L.PLAYER + L.PLAYER_PROJECTILE + L.WORLD + L.OBSTACLE + L.EXPLOSION + L.MINION,
   [L.PLAYER_PROJECTILE] = L.ENEMY + L.WORLD + L.OBSTACLE,
   [L.ENEMY_PROJECTILE]  = L.PLAYER + L.WORLD + L.OBSTACLE,
   [L.PICKUP]            = L.PLAYER + L.PICKUP,
   [L.WORLD]             = L.PLAYER + L.ENEMY + L.PLAYER_PROJECTILE + L.ENEMY_PROJECTILE + L.OBSTACLE + L.MINION,
   [L.OBSTACLE]          = L.PLAYER + L.ENEMY + L.PLAYER_PROJECTILE + L.ENEMY_PROJECTILE + L.WORLD + L.EXPLOSION,
   [L.EXPLOSION]         = L.PLAYER + L.ENEMY + L.OBSTACLE,
   [L.MINION]            = L.ENEMY + L.WORLD + L.OBSTACLE,
}

-- Entity type to collision layer mapping
local EntityCollisionLayer = {
   Player = CollisionLayers.PLAYER,
   Enemy = CollisionLayers.ENEMY,
   Projectile = CollisionLayers.PLAYER_PROJECTILE,
   MeleeHitbox = CollisionLayers.PLAYER_PROJECTILE,
   EnemyProjectile = CollisionLayers.ENEMY_PROJECTILE,

   HealthPickup = CollisionLayers.PICKUP,
   Coin = CollisionLayers.PICKUP,
   Key = CollisionLayers.PICKUP,
   Bomb = CollisionLayers.PICKUP,
   Rock = CollisionLayers.OBSTACLE,
   Destructible = CollisionLayers.OBSTACLE,
   Chest = CollisionLayers.OBSTACLE,
   LockedChest = CollisionLayers.OBSTACLE,
   ShopItem = CollisionLayers.OBSTACLE,
   Explosion = CollisionLayers.EXPLOSION,
   Chick = CollisionLayers.MINION,
   Egg = CollisionLayers.MINION,
}

return {
   CollisionLayers = CollisionLayers,
   CollisionMasks = CollisionMasks,
   EntityCollisionLayer = EntityCollisionLayer,
}
