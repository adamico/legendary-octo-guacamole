-- Combat collision handlers
-- Handles damage dealing between Player, Enemies, Projectiles, and Melee

local GameConstants = require("src/game/game_config")
local GameState = require("src/game/game_state")
local Effects = require("src/systems/effects")
local FloatingText = require("src/systems/floating_text")

local CombatHandlers = {}

-- Helper: Apply damage, consuming overheal first before base HP
-- @param entity - Entity to damage (must have hp, overflow_hp properties)
-- @param damage - Amount of damage to apply
-- @return actual_damage - Damage applied to base HP (after overheal absorption)
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

-- Handler for MeleeHitbox hitting Enemy
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
      local vampiric_heal = damage * GameConstants.Player.vampiric_heal
      owner.hp = math.min(owner.hp + vampiric_heal, owner.max_hp)
      FloatingText.spawn_at_entity(owner, vampiric_heal, "heal")
   end
end

-- Handler for Projectile hitting Enemy
local function projectile_vs_enemy(projectile, enemy)
   -- Always destroy the projectile upon impact
   world.del(projectile)
   Effects.hit_impact(projectile, enemy)

   -- Skip damage if enemy is invulnerable
   if enemy.invuln_timer and enemy.invuln_timer > 0 then
      return
   end

   local damage = projectile.damage or GameConstants.Projectile.damage or 10
   enemy.hp = enemy.hp - damage
   enemy.invuln_timer = 10 -- Brief invulnerability after hit
   FloatingText.spawn_at_entity(enemy, -damage, "damage")

   -- Composite knockback: base player knockback + projectile knockback
   local proj_knockback = GameConstants.Projectile.Egg.knockback or 2
   local knockback = GameConstants.Player.base_knockback + proj_knockback
   Effects.apply_knockback(projectile, enemy, knockback)
end

-- Handler for Player touching Enemy (contact damage)
local function player_vs_enemy(player, enemy)
   if enemy.enemy_type == "Dasher" and enemy.dasher_fsm and enemy.dasher_fsm:is("dash") then
      enemy.dasher_collision = true
   end
   if player.invuln_timer and player.invuln_timer > 0 then
      return
   end
   local damage = enemy.contact_damage or 10
   if not GameState.cheats.godmode then
      apply_damage_with_overheal(player, damage)
      FloatingText.spawn_at_entity(player, -damage, "damage")
   end
   Effects.hit_impact(enemy, player, "heavy_shake")
   Effects.apply_knockback(enemy, player, 16)
   player.invuln_timer = 30
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
   player.invuln_timer = 30
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
   player.invuln_timer = 30
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
