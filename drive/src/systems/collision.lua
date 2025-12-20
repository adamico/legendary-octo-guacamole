-- Collision detection and resolution systems
local Entities = require("entities")
local GameConstants = require("constants")
local Effects = require("effects")

local Collision = {}

-- Collision Handlers Registry
Collision.CollisionHandlers = {
    entity = {},
    map = {}
}

-- Registry for Player + ProjectilePickup interaction
Collision.CollisionHandlers.entity["Player,ProjectilePickup"] = function(player, pickup)
    player.hp = player.hp + (pickup.recovery_amount or 16)

    -- Bank overflow HP for future mechanics
    if player.hp > player.max_hp then
        player.overflow_hp = (player.overflow_hp or 0) + (player.hp - player.max_hp)
        player.hp = player.max_hp
    end

    -- Visual/audio feedback
    Effects.pickup_collect(pickup)

    world.del(pickup)
end

-- Registry for Projectile + Map interaction
Collision.CollisionHandlers.map["Projectile"] = function(projectile, map_x, map_y)
    -- Spawn pickup at wall impact point
    -- Use projectile's own recovery_percent and shot_cost (inherited from player)
    local recovery = (projectile.shot_cost) * (projectile.recovery_percent)
    Entities.spawn_pickup_projectile(world, projectile.x, projectile.y, projectile.dir_x, projectile.dir_y, recovery,
        projectile.sprite_index)
    world.del(projectile)
end

-- Registry for Projectile + Enemy interaction
Collision.CollisionHandlers.entity["Projectile,Enemy"] = function(projectile, enemy)
    -- Deal damage to enemy
    enemy.hp = enemy.hp - (projectile.damage or GameConstants.Projectile.damage or 10)

    -- Visual/audio feedback (reusable effect)
    Effects.hit_impact(projectile, enemy)

    -- Apply knockback to enemy (pushed away from projectile)
    Effects.apply_knockback(projectile, enemy, 6)

    -- Destroy projectile
    world.del(projectile)

    -- Check if enemy died
    if enemy.hp <= 0 then
        -- Drop HP pickup (100% for MVP)
        local recovery = GameConstants.Player.shot_cost * GameConstants.Player.recovery_percent
        Entities.spawn_pickup_projectile(world, enemy.x, enemy.y, projectile.dir_x, projectile.dir_y, recovery,
            projectile.sprite_index)

        -- Delete enemy
        world.del(enemy)
    end
end

-- Registry for Player + Enemy interaction (contact damage)
Collision.CollisionHandlers.entity["Player,Enemy"] = function(player, enemy)
    -- Skip if player is invulnerable
    if player.invuln_timer and player.invuln_timer > 0 then
        return
    end

    -- Deal contact damage to player
    player.hp = player.hp - (enemy.contact_damage or 10)

    -- Visual/audio feedback (heavier for player damage)
    Effects.hit_impact(enemy, player, "heavy_shake")

    -- Apply knockback to player (pushed away from enemy)
    Effects.apply_knockback(enemy, player, 16)

    -- Set invulnerability frames (30 frames ≈ 0.5 seconds at 60fps)
    player.invuln_timer = 30

    -- Reset regen timer (player took damage = in combat)
    player.time_since_shot = 0
end

-- Helper: Check if a rectangular area overlaps any solid map tiles
local function is_solid(x, y, w, h)
    local GRID_SIZE = 16
    local SOLID_FLAG = 0

    local x1 = flr(x / GRID_SIZE)
    local y1 = flr(y / GRID_SIZE)
    local x2 = flr((x + w - 0.001) / GRID_SIZE)
    local y2 = flr((y + h - 0.001) / GRID_SIZE)

    for tx = x1, x2 do
        for ty = y1, y2 do
            if fget(mget(tx, ty), SOLID_FLAG) then
                return true
            end
        end
    end
    return false
end

Collision.is_solid = is_solid

-- Entity-Entity Collision Resolver
function Collision.resolve_entity_collisions(entity1)
    -- We iterate over all entities that might collide with entity1
    world.sys("collidable", function(entity2)
        if entity1 == entity2 then return end

        local type1 = entity1.type or ""
        local type2 = entity2.type or ""
        local key = type1..","..type2
        local handler = Collision.CollisionHandlers.entity[key]

        if handler and Collision.entity_collision(entity1, entity2) then
            handler(entity1, entity2)
        end
    end)()
end

-- Entity-Map Collision Resolver (Abstracted)
function Collision.resolve_map_collisions(entity)
    local x = entity.x
    local y = entity.y
    local w = entity.width or 16
    local h = entity.height or 16

    local handler = Collision.CollisionHandlers.map[entity.type or ""]

    local function check(axis, vox, voy)
        local sub = entity["sub_"..axis]
        local vel = entity["vel_"..axis]
        local move = flr(sub + vel)
        if sub + vel < 0 and sub + vel ~= move then
            move = ceil(sub + vel) - 1
        end

        local cx = x + vox + (axis == "x" and move or 0)
        local cy = y + voy + (axis == "y" and move or 0)

        if is_solid(cx, cy, w, h) then
            if handler then handler(entity, cx, cy) end
            entity["vel_"..axis] = 0
            entity["sub_"..axis] = 0
            return 0
        end
        return move
    end

    local mx = check("x", 0, 0)
    check("y", entity.sub_x == 0 and 0 or mx, 0)
end

-- Entity collision system: generic overlap check
function Collision.entity_collision(entity1, entity2)
    return entity1.x < entity2.x + entity2.width and
       entity1.x + entity1.width > entity2.x and
       entity1.y < entity2.y + entity2.height and
       entity1.y + entity1.height > entity2.y
end

return Collision
