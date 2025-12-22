-- Collision detection and resolution systems
local Entities = require("entities")
local GameConstants = require("constants")
local Effects = require("effects")

local Collision = {}

-- Get hitbox bounds in world space
-- Returns {x, y, w, h} for collision detection
-- Supports per-direction hitboxes via entity.hitbox[direction] table
-- Falls back to hitbox_* properties, then width/height
local function get_hitbox(entity)
    local w, h, ox, oy

    -- Check for direction-based hitbox table
    if entity.hitbox then
        local dir = entity.direction or entity.current_direction
        local dir_hb = dir and entity.hitbox[dir]
        if dir_hb then
            w = dir_hb.w
            h = dir_hb.h
            ox = dir_hb.ox or 0
            oy = dir_hb.oy or 0
        end
    end

    -- Fallback to simple hitbox properties
    w = w or entity.hitbox_width or entity.width or 16
    h = h or entity.hitbox_height or entity.height or 16
    ox = ox or entity.hitbox_offset_x or 0
    oy = oy or entity.hitbox_offset_y or 0

    return {
        x = entity.x + ox + (entity.sprite_offset_x or 0),
        y = entity.y + oy + (entity.sprite_offset_y or 0),
        w = w,
        h = h
    }
end

Collision.get_hitbox = get_hitbox

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

-- Registry for EnemyProjectile + Map interaction
Collision.CollisionHandlers.map["EnemyProjectile"] = function(projectile, map_x, map_y)
    -- Visual feedback (optional particles)
    -- Destroy projectile
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

-- Registry for EnemyProjectile + Player interaction
Collision.CollisionHandlers.entity["EnemyProjectile,Player"] = function(projectile, player)
    -- Skip if player is invulnerable
    if player.invuln_timer and player.invuln_timer > 0 then
        return
    end

    -- Deal damage to player
    player.hp = player.hp - (projectile.damage or 10)

    -- Visual/audio feedback
    Effects.hit_impact(projectile, player, "heavy_shake")

    -- Apply knockback to player
    Effects.apply_knockback(projectile, player, 8)

    -- Set invulnerability frames
    player.invuln_timer = 30

    -- Reset regen timer
    player.time_since_shot = 0

    -- Destroy projectile
    world.del(projectile)
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
            local tile = mget(tx, ty)
            if tile and fget(tile, SOLID_FLAG) then
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
    local hb = get_hitbox(entity)
    local x = hb.x
    local y = hb.y
    local w = hb.w
    local h = hb.h

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

-- Entity collision system: generic overlap check using hitboxes
function Collision.entity_collision(entity1, entity2)
    local hb1 = get_hitbox(entity1)
    local hb2 = get_hitbox(entity2)
    return hb1.x < hb2.x + hb2.w and
       hb1.x + hb1.w > hb2.x and
       hb1.y < hb2.y + hb2.h and
       hb1.y + hb1.h > hb2.y
end

return Collision
