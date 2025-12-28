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

-- Helper: Destroy a destructible entity
local function destroy_destructible(destructible, attacker)
    if destructible.dead then return end

    destructible.dead = true
    world.del(destructible)

    -- Visual effect (simple particles or shake could be added here)
    -- Effects.shatter(destructible)

    -- 10% chance to spawn health pickup
    if rnd() < 0.1 then
        local cx = destructible.x + destructible.width / 2
        local cy = destructible.y + destructible.height / 2
        Entities.spawn_pickup(world, cx, cy, "HealthPickup")
    end
end

Handlers.map["Projectile"] = function(projectile, map_x, map_y, tx, ty, tile, room)
    local recovery = (projectile.shot_cost or 0) * (projectile.recovery_percent or 0)
    Entities.spawn_pickup_projectile(world, projectile.x, projectile.y, projectile.dir_x, projectile.dir_y, recovery,
        projectile.sprite_index, projectile.z)
    world.del(projectile)
end

Handlers.map["EnemyProjectile"] = function(projectile, map_x, map_y, tx, ty, tile, room)
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
local HitboxUtils = require("src/utils/hitbox_utils")

-- Push entity1 out of entity2 (AABB minimum penetration resolution)
local function push_out(entity, obstacle)
    local e_hb = HitboxUtils.get_hitbox(entity)
    local o_hb = HitboxUtils.get_hitbox(obstacle)

    -- Calculate overlap on each axis
    local overlap_left = (e_hb.x + e_hb.w) - o_hb.x   -- entity right vs obstacle left
    local overlap_right = (o_hb.x + o_hb.w) - e_hb.x  -- obstacle right vs entity left
    local overlap_top = (e_hb.y + e_hb.h) - o_hb.y    -- entity bottom vs obstacle top
    local overlap_bottom = (o_hb.y + o_hb.h) - e_hb.y -- obstacle bottom vs entity top

    -- Find minimum penetration axis
    local min_overlap = overlap_left
    local push_x, push_y = -overlap_left, 0

    if overlap_right < min_overlap then
        min_overlap = overlap_right
        push_x, push_y = overlap_right, 0
    end
    if overlap_top < min_overlap then
        min_overlap = overlap_top
        push_x, push_y = 0, -overlap_top
    end
    if overlap_bottom < min_overlap then
        min_overlap = overlap_bottom
        push_x, push_y = 0, overlap_bottom
    end

    -- Apply push to entity position
    entity.x = entity.x + push_x
    entity.y = entity.y + push_y

    -- Zero velocity in push direction to prevent jittering
    if push_x ~= 0 then entity.vel_x = 0 end
    if push_y ~= 0 then entity.vel_y = 0 end
end

-- Player/Enemy hitting Rock or Destructible -> push out
Handlers.entity["Player,Rock"] = function(player, rock) push_out(player, rock) end
Handlers.entity["Player,Destructible"] = function(player, dest) push_out(player, dest) end
Handlers.entity["Enemy,Rock"] = function(enemy, rock) push_out(enemy, rock) end
Handlers.entity["Enemy,Destructible"] = function(enemy, dest) push_out(enemy, dest) end

-- Helper: spawn projectile pickup and delete projectile
local function projectile_hit_obstacle(projectile)
    local recovery = (projectile.shot_cost or 0) * (projectile.recovery_percent or 0)
    if recovery > 0 then
        Entities.spawn_pickup_projectile(world, projectile.x, projectile.y,
            projectile.dir_x, projectile.dir_y, recovery, projectile.sprite_index, projectile.z)
    end
    world.del(projectile)
end

-- Projectile hitting Rock -> spawn pickup, delete projectile
Handlers.entity["Projectile,Rock"] = function(projectile, rock)
    projectile_hit_obstacle(projectile)
end

-- Projectile hitting Destructible -> destroy it, spawn pickup, delete projectile
Handlers.entity["Projectile,Destructible"] = function(projectile, destructible)
    destroy_destructible(destructible, projectile)
    projectile_hit_obstacle(projectile)
end

-- EnemyProjectile hitting Rock -> delete projectile (no pickup for enemies)
Handlers.entity["EnemyProjectile,Rock"] = function(projectile, rock)
    world.del(projectile)
end

-- EnemyProjectile hitting Destructible -> destroy it, delete projectile
Handlers.entity["EnemyProjectile,Destructible"] = function(projectile, destructible)
    destroy_destructible(destructible, projectile)
    world.del(projectile)
end

return Handlers
