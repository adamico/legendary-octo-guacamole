local Entities = require("src/entities")
local GameConstants = require("src/game/game_config")
local GameState = require("src/game/game_state")
local Effects = require("src/systems/effects")
local FloatingText = require("src/systems/floating_text")

local Handlers = {
    entity = {},
    map = {},
    tile = {}
}

local PickupEffects = {}

PickupEffects.health = function(player, pickup)
    local heal_amount = pickup.recovery_amount or 16
    player.hp = player.hp + heal_amount

    if player.hp > player.max_hp then
        player.overflow_hp = (player.overflow_hp or 0) + (player.hp - player.max_hp)
        player.hp = player.max_hp
    end

    FloatingText.spawn_at_entity(player, heal_amount, "heal")
end

-- Handler for MeleeHitbox hitting Enemy
Handlers.entity["MeleeHitbox,Enemy"] = function(hitbox, enemy)
    -- Skip if enemy is invulnerable
    if enemy.invuln_timer and enemy.invuln_timer > 0 then
        return
    end

    -- Deal damage to enemy
    local damage = hitbox.melee_damage or 10
    enemy.hp = enemy.hp - damage
    enemy.invuln_timer = 10 -- Brief invulnerability after hit
    FloatingText.spawn_at_entity(enemy, -damage, "damage")
    Effects.hit_impact(hitbox, enemy)
    -- Composite knockback: base player knockback + melee knockback
    local knockback = GameConstants.Player.base_knockback + GameConstants.Player.melee_knockback
    Effects.apply_knockback(hitbox, enemy, knockback)

    -- Vampiric healing: Heal player for % of damage dealt
    local owner = hitbox.owner_entity
    if owner and owner.type == "Player" then
        local vampiric_heal = damage * GameConstants.Player.vampiric_heal
        owner.hp = math.min(owner.hp + vampiric_heal, owner.max_hp)
        FloatingText.spawn_at_entity(owner, vampiric_heal, "heal")
    end
end

local function handle_pickup_collection(player, pickup)
    local effect_type = pickup.pickup_effect or "health"
    local effect_handler = PickupEffects[effect_type]
    assert(effect_handler, "Unknown pickup_effect '"..effect_type.."'")(player, pickup)

    Effects.pickup_collect(pickup)
    world.del(pickup)
end

Handlers.entity["Player,ProjectilePickup"] = handle_pickup_collection
Handlers.entity["Player,HealthPickup"] = handle_pickup_collection

-- Helper: Check if a tile is destructible
local function is_destructible_tile(tile)
    for _, t in ipairs(DESTRUCTIBLE_TILES) do
        if tile == t then return true end
    end
    return false
end

-- Helper: Destroy a tile and maybe spawn a pickup
local function destroy_tile(tx, ty, projectile)
    -- Replace destructible with a random floor tile
    local floor_tile = FLOOR_TILES[flr(rnd(#FLOOR_TILES)) + 1]
    mset(tx, ty, floor_tile)

    -- Small chance to spawn health pickup (10%)
    if rnd(100) < 10 then
        local px = tx * GRID_SIZE + GRID_SIZE / 2
        local py = ty * GRID_SIZE + GRID_SIZE / 2
        Entities.spawn_pickup(world, px, py, "HealthPickup")
    end
end

-- Helper: Destroy a destructible entity
local function destroy_destructible(destructible, attacker)
    if destructible.dead then return end

    destructible.dead = true
    world.del(destructible)

    -- Visual effect (simple particles or shake could be added here)
    -- Effects.shatter(destructible)

    -- 10% chance to spawn health pickup
    if rnd(100) < 10 then
        local cx = destructible.x + destructible.width / 2
        local cy = destructible.y + destructible.height / 2
        Entities.spawn_pickup(world, cx, cy, "HealthPickup")
    end
end

Handlers.map["Projectile"] = function(projectile, map_x, map_y, tx, ty, tile, room)
    -- Check if we hit a destructible (tile or entity)
    if tile and (is_destructible_tile(tile) or (type(tile) == "table" and tile.destructible)) then
        if type(tile) == "table" then
            destroy_destructible(tile, projectile)
        else
            destroy_tile(tx, ty, projectile)
        end
        world.del(projectile)
        return
    end

    -- Normal wall collision: spawn pickup
    local recovery = (projectile.shot_cost or 0) * (projectile.recovery_percent or 0)
    Entities.spawn_pickup_projectile(world, projectile.x, projectile.y, projectile.dir_x, projectile.dir_y, recovery,
        projectile.sprite_index, projectile.z)
    world.del(projectile)
end

Handlers.map["EnemyProjectile"] = function(projectile, map_x, map_y, tx, ty, tile, room)
    -- Check if we hit a destructible (tile or entity)
    if tile and (is_destructible_tile(tile) or (type(tile) == "table" and tile.destructible)) then
        if type(tile) == "table" then
            destroy_destructible(tile, projectile)
        else
            destroy_tile(tx, ty, projectile)
        end
    end
    world.del(projectile)
end

Handlers.map["Enemy"] = function(enemy, map_x, map_y)
    enemy.hit_wall = true
    if enemy.enemy_type == "Dasher" and enemy.dasher_fsm and enemy.dasher_fsm:is("dash") then
        enemy.dasher_collision = true
    end
end

Handlers.entity["Projectile,Enemy"] = function(projectile, enemy)
    local damage = projectile.damage or GameConstants.Projectile.damage or 10
    enemy.hp = enemy.hp - damage
    FloatingText.spawn_at_entity(enemy, -damage, "damage")
    Effects.hit_impact(projectile, enemy)
    -- Composite knockback: base player knockback + projectile knockback
    local proj_knockback = GameConstants.Projectile.Laser.knockback or 2
    local knockback = GameConstants.Player.base_knockback + proj_knockback
    Effects.apply_knockback(projectile, enemy, knockback)
    world.del(projectile)
end

Handlers.entity["Player,Enemy"] = function(player, enemy)
    if enemy.enemy_type == "Dasher" and enemy.dasher_fsm and enemy.dasher_fsm:is("dash") then
        enemy.dasher_collision = true
    end
    if player.invuln_timer and player.invuln_timer > 0 then
        return
    end
    local damage = enemy.contact_damage or 10
    if not GameState.cheats.godmode then
        player.hp = player.hp - damage
        FloatingText.spawn_at_entity(player, -damage, "damage")
    end
    Effects.hit_impact(enemy, player, "heavy_shake")
    Effects.apply_knockback(enemy, player, 16)
    player.invuln_timer = 30
    player.time_since_shot = 0
end

Handlers.entity["Player,Skull"] = function(player, skull)
    if player.invuln_timer and player.invuln_timer > 0 then
        return
    end
    local damage = skull.contact_damage or 20
    if not GameState.cheats.godmode then
        player.hp = player.hp - damage
        FloatingText.spawn_at_entity(player, -damage, "damage")
    end
    skull.hp = skull.hp - 1
    Effects.hit_impact(skull, player, "heavy_shake")
    Effects.apply_knockback(skull, player, 16)
    player.invuln_timer = 30
    player.time_since_shot = 0
end

Handlers.entity["EnemyProjectile,Player"] = function(projectile, player)
    if player.invuln_timer and player.invuln_timer > 0 then
        return
    end
    local damage = projectile.damage or 10
    if not GameState.cheats.godmode then
        player.hp = player.hp - damage
        FloatingText.spawn_at_entity(player, -damage, "damage")
    end
    Effects.hit_impact(projectile, player, "heavy_shake")
    Effects.apply_knockback(projectile, player, 8)
    player.invuln_timer = 30
    player.time_since_shot = 0
    world.del(projectile)
end

-- Obstacle collision handlers (Rocks, Destructibles)

-- Simple push-back logic for entities hitting obstacles
-- This pushes entity1 OUT of entity2
local function handle_obstacle_collision(entity, obstacle)
    Effects.resolve_collision(entity, obstacle)
end

Handlers.entity["Player,Rock"] = handle_obstacle_collision
Handlers.entity["Player,Destructible"] = handle_obstacle_collision
Handlers.entity["Enemy,Rock"] = handle_obstacle_collision
Handlers.entity["Enemy,Destructible"] = handle_obstacle_collision

-- Projectile hitting Destructible
Handlers.entity["Projectile,Destructible"] = function(projectile, destructible)
    destroy_destructible(destructible, projectile)
    world.del(projectile)
end

-- Projectile hitting Rock
Handlers.entity["Projectile,Rock"] = function(projectile, rock)
    -- Same behavior as hitting a wall: chance to spawn pickup, destroy projectile
    local recovery = (projectile.shot_cost or 0) * (projectile.recovery_percent or 0)
    if recovery > 0 then
        Entities.spawn_pickup_projectile(world, projectile.x, projectile.y, projectile.dir_x, projectile.dir_y, recovery,
            projectile.sprite_index, projectile.z)
    end
    world.del(projectile)
end

-- EnemyProjectile hitting Destructible
Handlers.entity["EnemyProjectile,Destructible"] = function(projectile, destructible)
    destroy_destructible(destructible)
    world.del(projectile)
end

-- EnemyProjectile hitting Rock
Handlers.entity["EnemyProjectile,Rock"] = function(projectile, rock)
    world.del(projectile)
end

return Handlers
