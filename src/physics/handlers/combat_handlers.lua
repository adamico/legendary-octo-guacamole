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
--- @param hitbox MeleeHitbox entity
--- @param enemy Enemy entity
local function melee_vs_enemy(hitbox, enemy)
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
      local heal_percent = owner.vampiric_heal or GameConstants.Player.vampiric_heal or 0.3
      local vampiric_heal = damage * heal_percent
      owner.hp = math.min(owner.hp + vampiric_heal, owner.max_hp)
      FloatingText.spawn_at_entity(owner, vampiric_heal, "heal")
   end
end

-- Handler for Projectile hitting Enemy
local function projectile_vs_enemy(projectile, enemy)
   -- Prevent double processing if already handled
   if projectile.hit_obstacle then return end
   projectile.hit_obstacle = true

   -- Trigger impact effect
   Effects.hit_impact(projectile, enemy)

   -- Apply knockback from projectile direction
   local knockback = GameConstants.Player.base_knockback or 4
   Effects.apply_knockback(projectile, enemy, knockback)

   -- Target painting: Mark this enemy as priority target for all chicks
   AI.ChickAI.paint_target(enemy)

   -- Get outcome values from projectile (passed from player stats or config)
   -- Using config defaults if not on projectile, though Shooter system usually copies them
   local dud_damage = projectile.dud_damage or GameConstants.Player.dud_damage or 3
   local leech_damage = projectile.leech_damage or GameConstants.Player.leech_damage or 5
   local leech_heal = projectile.leech_heal or GameConstants.Player.leech_heal or 5
   local hatch_time = projectile.hatch_time or GameConstants.Player.hatch_time or 120

   -- Sticky Yolk effect config (stun + slow instead of knockback)
   -- Read from projectile (passed from player stats) or fall back to constants
   local stun_dur = GameConstants.Player.egg_stun_duration or 12
   local slow_dur = projectile.egg_slow_duration or GameConstants.Player.egg_slow_duration or 60
   local slow_factor = projectile.egg_slow_factor or GameConstants.Player.egg_slow_factor or 0.5
   local attach_dur = GameConstants.Player.chick_attach_duration or 60

   local roll_dud = projectile.roll_dud_chance or GameConstants.Player.roll_dud_chance or 0.50
   local roll_hatch = projectile.roll_hatch_chance or GameConstants.Player.roll_hatch_chance or 0.35
   -- Remainder is Leech (approx 0.15)

   local hb = HitboxUtils.get_hitbox(projectile)
   local spawn_x = hb.x + hb.w / 2 - 8
   local spawn_y = hb.y + hb.h / 2 - 8
   local spawn_z = projectile.z or 0

   -- Single roll with 3 outcomes
   local roll = rnd()
   local threshold_dud = roll_dud
   local threshold_hatch = roll_dud + roll_hatch

   if roll < threshold_dud then
      -- The Dud : 3 Dmg, splats harmlessly + Sticky Yolk (stun/slow)
      if not (enemy.invuln_timer and enemy.invuln_timer > 0) then
         enemy.hp = enemy.hp - dud_damage
         enemy.invuln_timer = 10
         FloatingText.spawn_at_entity(enemy, -dud_damage, "damage")
         -- Sticky Yolk: stun + slow instead of knockback
         Effects.apply_sticky_yolk(enemy, stun_dur, slow_dur, slow_factor)
      end
      -- Visual splat effect for Dud
      Effects.spawn_visual_effect(world, spawn_x, spawn_y, BROKEN_EGG_SPRITE, 15)
   elseif roll < threshold_hatch then
      -- The Hatching (35%): No damage, spawn chick attached to enemy (Face-Hugger)
      -- Apply Sticky Yolk so enemy can't escape during chick hatch
      Effects.apply_sticky_yolk(enemy, stun_dur, slow_dur, slow_factor)

      -- Spawn egg at enemy position with attachment
      Entities.spawn_egg(world, enemy.x, enemy.y, {
         hatch_timer = hatch_time,
         z = spawn_z,
         attachment_target = enemy,
         attachment_timer = attach_dur,
         broodmother_active = projectile.broodmother_active,
      })
   else
      -- Parasitic Drain (approx 15%): Partial damage + spawn health pickup + Sticky Yolk
      if not (enemy.invuln_timer and enemy.invuln_timer > 0) then
         enemy.hp = enemy.hp - leech_damage
         enemy.invuln_timer = 10
         FloatingText.spawn_at_entity(enemy, -leech_damage, "damage")
         -- Sticky Yolk: stun + slow instead of knockback
         Effects.apply_sticky_yolk(enemy, stun_dur, slow_dur, slow_factor)
      end
      -- Spawn health pickup (blood glob)
      local sx, sy = DungeonManager.snap_to_nearest_floor(spawn_x, spawn_y + spawn_z, DungeonManager.current_room)
      if not sx then sx, sy = spawn_x, spawn_y + spawn_z end -- Fall back to original position
      Entities.spawn_health_pickup(world, sx, sy, leech_heal)
   end
   world.del(projectile)
end

--- Handler for Player touching Enemy (contact damage)
--- @param player Player entity
--- @param enemy Enemy entity
local function player_vs_enemy(player, enemy)
   if enemy.enemy_type == "Dasher" and enemy.dasher_fsm and enemy.dasher_fsm:is("dash") then
      enemy.dasher_collision = true
   end
   if player.invuln_timer and player.invuln_timer > 0 then
      return
   end
   local damage = enemy.contact_damage or 10
   -- Apply damage reduction if player has upgrade
   damage = math.floor(damage * (player.damage_reduction or 1.0))
   if not GameState.cheats.godmode then
      apply_damage_with_overheal(player, damage)
      FloatingText.spawn_at_entity(player, -damage, "damage")
   end
   Effects.hit_impact(enemy, player, "heavy_shake")
   Effects.apply_knockback(enemy, player, 16)
   player.invuln_timer = player.invulnerability_duration or 120
   player.time_since_shot = 0
end

-- Handler for EnemyProjectile hitting Player
local function enemy_projectile_vs_player(projectile, player)
   if player.invuln_timer and player.invuln_timer > 0 then
      return
   end
   local damage = projectile.damage or 10
   if not GameState.cheats.godmode then
      apply_damage_with_overheal(player, damage)
      FloatingText.spawn_at_entity(player, -damage, "damage")
   end
   Effects.hit_impact(projectile, player, "heavy_shake")
   Effects.apply_knockback(projectile, player, 8)
   player.invuln_timer = player.invulnerability_duration or 120
   player.time_since_shot = 0
   world.del(projectile)
end

-- Helper: Apply radial knockback from explosion center
local function apply_explosion_knockback(explosion, target, strength)
   -- Use stored explosion center for consistent radial knockback
   local src_cx = explosion.explosion_center_x or (explosion.x + (explosion.width or 0) / 2)
   local src_cy = explosion.explosion_center_y or (explosion.y + (explosion.height or 0) / 2)
   local tgt_cx = target.x + (target.width or 0) / 2
   local tgt_cy = target.y + (target.height or 0) / 2

   local dx = tgt_cx - src_cx
   local dy = tgt_cy - src_cy

   -- Normalize direction
   local len = sqrt(dx * dx + dy * dy)
   if len > 0 then
      dx = dx / len
      dy = dy / len
   else
      dx, dy = 0, -1 -- Default push up if overlapping
   end

   target.knockback_vel_x = dx * strength
   target.knockback_vel_y = dy * strength
end

-- Handler for Explosion hitting Player
local function explosion_vs_player(explosion, player)
   if player.invuln_timer and player.invuln_timer > 0 then
      return
   end

   local damage = explosion.explosion_damage or 20
   if not GameState.cheats.godmode then
      apply_damage_with_overheal(player, damage)
      FloatingText.spawn_at_entity(player, -damage, "damage")
   end
   Effects.hit_impact(explosion, player, "heavy_shake")
   apply_explosion_knockback(explosion, player, 16)
   player.invuln_timer = player.invulnerability_duration or 120
end

-- Handler for Explosion hitting Enemy
local function explosion_vs_enemy(explosion, enemy)
   if enemy.invuln_timer and enemy.invuln_timer > 0 then
      return
   end

   local damage = explosion.explosion_damage or 20
   enemy.hp = enemy.hp - damage
   enemy.invuln_timer = 10
   FloatingText.spawn_at_entity(enemy, -damage, "damage")
   Effects.hit_impact(explosion, enemy)
   apply_explosion_knockback(explosion, enemy, 12)
end

-- Register all combat handlers
function CombatHandlers.register(handlers)
   handlers.entity["MeleeHitbox,Enemy"] = melee_vs_enemy
   handlers.entity["Projectile,Enemy"] = projectile_vs_enemy
   handlers.entity["Player,Enemy"] = player_vs_enemy
   handlers.entity["EnemyProjectile,Player"] = enemy_projectile_vs_player
   handlers.entity["Explosion,Player"] = explosion_vs_player
   handlers.entity["Explosion,Enemy"] = explosion_vs_enemy
   handlers.entity["Player,Explosion"] = function(player, explosion)
      explosion_vs_player(explosion, player)
   end
   handlers.entity["Enemy,Explosion"] = function(enemy, explosion)
      explosion_vs_enemy(explosion, enemy)
   end
end

return CombatHandlers
