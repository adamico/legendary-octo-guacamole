local Entities = require("entities")
local GameConstants = require("constants")
local Effects = require("effects")

local Handlers = {
    entity = {},
    map = {},
    tile = {}
}

local PickupEffects = {}

PickupEffects.health = function(player, pickup)
    player.hp = player.hp + (pickup.recovery_amount or 16)

    if player.hp > player.max_hp then
        player.overflow_hp = (player.overflow_hp or 0) + (player.hp - player.max_hp)
        player.hp = player.max_hp
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
    enemy.hp = enemy.hp - (projectile.damage or GameConstants.Projectile.damage or 10)
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
    if not GameConstants.cheats.godmode then
        player.hp = player.hp - (enemy.contact_damage or 10)
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
    if not GameConstants.cheats.godmode then
        player.hp = player.hp - (skull.contact_damage or 20)
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
    if not GameConstants.cheats.godmode then
        player.hp = player.hp - (projectile.damage or 10)
    end
    Effects.hit_impact(projectile, player, "heavy_shake")
    Effects.apply_knockback(projectile, player, 8)
    player.invuln_timer = 30
    player.time_since_shot = 0
    world.del(projectile)
end

return Handlers
