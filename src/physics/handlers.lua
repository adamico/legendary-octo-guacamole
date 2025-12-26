local Entities = require("src/entities")
local GameConstants = require("src/constants")
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
    -- Deal damage to enemy
    local damage = hitbox.melee_damage or 10
    enemy.hp = enemy.hp - damage
    FloatingText.spawn_at_entity(enemy, -damage, "damage")
    Effects.hit_impact(hitbox, enemy)
    Effects.apply_knockback(hitbox, enemy, 8)

    -- Vampiric healing: Heal player for damage dealt (capped at missing health or full damage?)
    -- User said: "100% vampiric effect"
    local owner = hitbox.owner_entity
    if owner and owner.type == "Player" then
        -- Cap heal to 100% of damage dealt
        local heal_amount = damage
        owner.hp = math.min(owner.hp + heal_amount, owner.max_hp)
        FloatingText.spawn_at_entity(owner, heal_amount, "heal")
    end

    -- Hitbox is destroyed on first contact? Or multi-hit?
    -- Usually melee goes through enemies (multi-hit) but with a duration of 6 frames, it might hit same enemy multiple times.
    -- For simplicity and balance, maybe delete it to prevent multi-proc?
    -- But then it's single target.
    -- If we keep it, we need an invulnerability list on the hitbox.
    -- Let's stick to simple single-hit for now, delete on contact.
    world.del(hitbox)
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

Handlers.map["Projectile"] = function(projectile, map_x, map_y)
    local recovery = (projectile.shot_cost) * (projectile.recovery_percent)
    Entities.spawn_pickup_projectile(world, projectile.x, projectile.y, projectile.dir_x, projectile.dir_y, recovery,
        projectile.sprite_index)
    world.del(projectile)
end

Handlers.map["EnemyProjectile"] = function(projectile, map_x, map_y)
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
    Effects.apply_knockback(projectile, enemy, 6)
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
    if not GameConstants.cheats.godmode then
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
    if not GameConstants.cheats.godmode then
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
    if not GameConstants.cheats.godmode then
        player.hp = player.hp - damage
        FloatingText.spawn_at_entity(player, -damage, "damage")
    end
    Effects.hit_impact(projectile, player, "heavy_shake")
    Effects.apply_knockback(projectile, player, 8)
    player.invuln_timer = 30
    player.time_since_shot = 0
    world.del(projectile)
end

return Handlers
