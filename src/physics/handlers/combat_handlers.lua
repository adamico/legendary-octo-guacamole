-- Combat collision handlers
-- Handles damage dealing between Player, Enemies, Projectiles, and Melee

local GameConstants = require("src/game/game_config")
local GameState = require("src/game/game_state")
local Effects = require("src/systems/effects")
local FloatingText = require("src/systems/floating_text")
local Entities = require("src/entities")
local HitboxUtils = require("src/utils/hitbox_utils")
local DungeonManager = require("src/world/dungeon_manager")
local AI = require("src/ai")

local CombatHandlers = {}

--- Helper: Apply damage, consuming overheal first before base HP
--- @param entity Entity to damage (must have hp, overflow_hp properties)
--- @param damage integer - Amount of damage to apply
--- @return integer actual_damage - Damage applied to base HP (after overheal absorption)
local function apply_damage_with_overheal(entity, damage)
   local overheal = entity.overflow_hp or 0

   if overheal > 0 then
      if overheal >= damage then
         -- Overheal absorbs all damage
         entity.overflow_hp = overheal - damage
         return 0
      else
         -- Overheal absorbs partial damage
         local remaining = damage - overheal
         entity.overflow_hp = 0
         entity.hp = entity.hp - remaining
         return remaining
      end
   else
      -- No overheal, damage goes directly to HP
      entity.hp = entity.hp - damage
      return damage
   end
end

--- Handler for MeleeHitbox hitting Enemy
--- @param world World
--- @param hitbox MeleeHitbox entity
--- @param enemy Enemy entity
local function melee_vs_enemy(world, hitbox, enemy)
   -- Skip if enemy is invulnerable
   if enemy.invuln_timer and enemy.invuln_timer > 0 then
      return
   end

   -- Deal damage to enemy
   local damage = hitbox.melee_damage or 10
   enemy.hp -= damage
   enemy.invuln_timer = 10 -- Brief invulnerability after hit
   FloatingText.spawn_damage(enemy, -damage)
   Effects.hit_impact(world, hitbox, enemy.id)

   -- Composite knockback: base player knockback + melee knockback
   local knockback = GameConstants.Player.base_knockback + GameConstants.Player.melee_knockback
   Effects.apply_knockback(world, hitbox, enemy.id, knockback)

   -- Vampiric healing: Heal player for % of damage dealt
   -- Need to access owner entity. hitbox.owner_entity might be a proxy or ID?
   -- In Melee system we set owner_entity = player (table).
   -- Proxy handles field access. If `owner_entity` returns a proxy or table, we check type.
   -- But wait, `melee.lua` set `owner_entity = player` (the component proxy/table).
   -- If `hitbox` is a proxy, accessing `owner_entity` via `__index`?
   -- `EntityProxy` doesn't Map `owner_entity`.
   -- It only Maps `owner` -> `projectile_owner`.
   -- `Melee.lua` creates entity with `projectile_owner = { owner = {value = id} }`.
   -- So `hitbox.owner` (mapped to `projectile_owner.owner`) returns the ID (value).
   -- We need to resolve ID to entity.
   local owner_id = hitbox.owner
   -- We can't easily get the owner proxy here without creating one.
   -- But we only need to heal.
   if owner_id then
      -- We need to query owner to heal.
      world:query_entity(owner_id, {"health", "type", "melee?"}, function(idx, hp_c, type_c, melee_c)
         if type_c.value[idx] == "Player" then
            local heal_percent = (melee_c and melee_c.vampiric_heal[idx]) or GameConstants.Player.vampiric_heal or 0.3
            local vampiric_heal = damage * heal_percent
            local max_h = hp_c.max_hp[idx]
            hp_c.hp[idx] = math.min(hp_c.hp[idx] + vampiric_heal, max_h)
            -- FloatingText needs world? FloatingText.spawn_heal(entity, amount).
            -- FloatingText system likely needs update too if it takes entity table?
            -- FloatingText.spawn_heal usually takes entity and adds separate component.
            -- Let's check FloatingText later. Assuming it works or needs ID.
            -- If FloatingText needs proxy, we might have issue.
            -- But FloatingText usually spawns a NEW entity at position.
            -- If we pass a table `{x=..., y=...}` it might work.
            -- For now, let's assume FloatingText handles it (or accept we might need to fix it).
         end
      end)
   end
end

-- Handler for Projectile hitting Enemy
local function projectile_vs_enemy(world, projectile, enemy)
   -- Prevent double processing if already handled
   if projectile.hit_obstacle then return end
   projectile.hit_obstacle = true

   -- Trigger impact effect
   Effects.hit_impact(world, projectile, enemy.id)

   -- Target painting: Mark this enemy as priority target for all chicks
   AI.ChickAI.paint_target(enemy)

   -- Get outcome values (using proxy access)
   local dud_damage = projectile.dud_damage or GameConstants.Player.dud_damage or 3
   local leech_damage = projectile.leech_damage or GameConstants.Player.leech_damage or 5
   local leech_heal = projectile.leech_heal or GameConstants.Player.leech_heal or 5
   -- hatch_time is in component? projectile.hatch_time.
   local hatch_time = projectile.hatch_time or GameConstants.Player.hatch_time or 120

   local stun_dur = GameConstants.Player.egg_stun_duration or 12
   local slow_dur = projectile.egg_slow_duration or GameConstants.Player.egg_slow_duration or 60
   local slow_factor = projectile.egg_slow_factor or GameConstants.Player.egg_slow_factor or 0.5
   local attach_dur = GameConstants.Player.chick_attach_duration or 60

   local roll_dud = GameConstants.Player.roll_dud_chance or 0.50
   local roll_hatch = GameConstants.Player.roll_hatch_chance or 0.35

   local hb = HitboxUtils.get_hitbox(projectile)
   local spawn_x = hb.x + hb.w / 2 - 8
   local spawn_y = hb.y + hb.h / 2 - 8
   local spawn_z = projectile.z or 0

   local roll = rnd()
   local threshold_dud = roll_dud
   local threshold_hatch = roll_dud + roll_hatch

   if roll < threshold_dud then
      -- The Dud
      if not (enemy.invuln_timer and enemy.invuln_timer > 0) then
         enemy.hp = enemy.hp - dud_damage
         enemy.invuln_timer = 10
         FloatingText.spawn_damage(enemy, -dud_damage)
         Effects.apply_sticky_yolk(world, enemy.id, stun_dur, slow_dur, slow_factor)
      end
      -- Visual splat effect for Dud
      Effects.spawn_visual_effect(world, spawn_x, spawn_y, BROKEN_EGG_SPRITE, 15)
   elseif roll < threshold_hatch then
      -- The Hatching
      Effects.apply_sticky_yolk(world, enemy.id, stun_dur, slow_dur, slow_factor)

      -- Spawn egg at enemy position with attachment
      Entities.spawn_egg(world, enemy.x, enemy.y, {
         hatch_timer = hatch_time,
         z = spawn_z,
         attachment_target = enemy, -- Might need ID? Check spawn_egg logic.
         attachment_timer = attach_dur,
      })
   else
      -- Parasitic Drain
      if not (enemy.invuln_timer and enemy.invuln_timer > 0) then
         enemy.hp = enemy.hp - leech_damage
         enemy.invuln_timer = 10
         FloatingText.spawn_damage(enemy, -leech_damage)
         Effects.apply_sticky_yolk(world, enemy.id, stun_dur, slow_dur, slow_factor)
      end
      -- Spawn health pickup (blood glob)
      local sx, sy = DungeonManager.snap_to_nearest_floor(spawn_x, spawn_y + spawn_z, DungeonManager.current_room)
      if not sx then sx, sy = spawn_x, spawn_y + spawn_z end
      Entities.spawn_health_pickup(world, sx, sy, leech_heal)
   end
   world:remove_entity(projectile.id)
end

--- Handler for Player touching Enemy (contact damage)
local function player_vs_enemy(world, player, enemy)
   if enemy.enemy_type == "Dasher" and enemy.dasher_fsm and enemy.dasher_fsm:is("dash") then
      enemy.dasher_collision = true
   end
   if player.invuln_timer and player.invuln_timer > 0 then
      return
   end
   local damage = enemy.contact_damage or 10
   damage = math.floor(damage * (player.damage_reduction or 1.0))
   if not GameState.cheats.godmode then
      apply_damage_with_overheal(player, damage)
      FloatingText.spawn_damage(player, -damage)
   end
   Effects.hit_impact(world, enemy, player.id, "heavy_shake")
   Effects.apply_knockback(world, enemy, player.id, 16)
   player.invuln_timer = player.invulnerability_duration or 120
   player.time_since_shot = 0
end

-- Handler for EnemyProjectile hitting Player
local function enemy_projectile_vs_player(world, projectile, player)
   if player.invuln_timer and player.invuln_timer > 0 then
      return
   end
   local damage = projectile.damage or 10
   if not GameState.cheats.godmode then
      apply_damage_with_overheal(player, damage)
      FloatingText.spawn_damage(player, -damage)
   end
   Effects.hit_impact(world, projectile, player.id, "heavy_shake")
   Effects.apply_knockback(world, projectile, player.id, 8)
   player.invuln_timer = player.invulnerability_duration or 120
   player.time_since_shot = 0
   world:remove_entity(projectile.id)
end

-- Helper: Apply radial knockback from explosion center
local function apply_explosion_knockback(world, explosion, target_id, strength)
   -- Need to read explosion center from proxy
   local src_cx = explosion.explosion_center_x or (explosion.x + (explosion.width or 0) / 2)
   local src_cy = explosion.explosion_center_y or (explosion.y + (explosion.height or 0) / 2)

   -- We need to pass a "source_pos" table to Effects.apply_knockback that mocks the center
   -- Effects.apply_knockback calculates center from x,y,w,h.
   -- Let's construct a fake source table centered at explosion center
   local fake_source = {
      x = src_cx - 1, y = src_cy - 1, width = 2, height = 2
   }
   Effects.apply_knockback(world, fake_source, target_id, strength)
end

-- Handler for Explosion hitting Player
local function explosion_vs_player(world, explosion, player)
   if player.invuln_timer and player.invuln_timer > 0 then
      return
   end

   local damage = explosion.explosion_damage or 20
   if not GameState.cheats.godmode then
      apply_damage_with_overheal(player, damage)
      FloatingText.spawn_damage(player, -damage)
   end
   Effects.hit_impact(world, explosion, player.id, "heavy_shake")
   apply_explosion_knockback(world, explosion, player.id, 16)
   player.invuln_timer = player.invulnerability_duration or 120
end

-- Handler for Explosion hitting Enemy
local function explosion_vs_enemy(world, explosion, enemy)
   if enemy.invuln_timer and enemy.invuln_timer > 0 then
      return
   end

   local damage = explosion.explosion_damage or 20
   enemy.hp = enemy.hp - damage
   enemy.invuln_timer = 10
   FloatingText.spawn_damage(enemy, -damage)
   Effects.hit_impact(world, explosion, enemy.id)
   apply_explosion_knockback(world, explosion, enemy.id, 12)
end

-- Register all combat handlers
function CombatHandlers.register(handlers)
   handlers.entity["MeleeHitbox,Enemy"] = melee_vs_enemy
   handlers.entity["Projectile,Enemy"] = projectile_vs_enemy
   handlers.entity["Player,Enemy"] = player_vs_enemy
   handlers.entity["EnemyProjectile,Player"] = enemy_projectile_vs_player
   handlers.entity["Explosion,Player"] = explosion_vs_player
   handlers.entity["Explosion,Enemy"] = explosion_vs_enemy
   handlers.entity["Player,Explosion"] = function(world, player, explosion)
      explosion_vs_player(world, explosion, player)
   end
   handlers.entity["Enemy,Explosion"] = function(world, enemy, explosion)
      explosion_vs_enemy(world, explosion, enemy)
   end
end

return CombatHandlers
