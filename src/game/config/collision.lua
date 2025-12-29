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
}

-- What each layer can collide with (bitmask)
local CollisionMasks = {
   [1] = 2 + 8 + 16 + 32 + 64 + 128, -- PLAYER: Enemy + EnemyProjectile + Pickup + World + Obstacle + Explosion
   [2] = 1 + 4 + 32 + 64 + 128,      -- ENEMY: Player + PlayerProjectile + World + Obstacle + Explosion
   [4] = 2 + 32 + 64,                -- PLAYER_PROJECTILE: Enemy + World + Obstacle
   [8] = 1 + 32 + 64,                -- ENEMY_PROJECTILE: Player + World + Obstacle
   [16] = 1 + 16,                    -- PICKUP: Player + other Pickups
   [32] = 1 + 2 + 4 + 8,             -- WORLD: Everything except Pickup
   [64] = 1 + 2 + 4 + 8 + 128,       -- OBSTACLE: Player + Enemy + Projectiles + Explosion
   [128] = 1 + 2 + 64,               -- EXPLOSION: Player + Enemy + Obstacle
}

-- Entity type to collision layer mapping
local EntityCollisionLayer = {
   Player = CollisionLayers.PLAYER,
   Enemy = CollisionLayers.ENEMY,
   Projectile = CollisionLayers.PLAYER_PROJECTILE,
   MeleeHitbox = CollisionLayers.PLAYER_PROJECTILE,
   EnemyProjectile = CollisionLayers.ENEMY_PROJECTILE,
   ProjectilePickup = CollisionLayers.PICKUP,
   HealthPickup = CollisionLayers.PICKUP,
   Coin = CollisionLayers.PICKUP,
   Key = CollisionLayers.PICKUP,
   Bomb = CollisionLayers.PICKUP,
   Rock = CollisionLayers.OBSTACLE,
   Destructible = CollisionLayers.OBSTACLE,
   Explosion = CollisionLayers.EXPLOSION,
   Chick = CollisionLayers.WORLD,
}

return {
   CollisionLayers = CollisionLayers,
   CollisionMasks = CollisionMasks,
   EntityCollisionLayer = EntityCollisionLayer,
}
