local Entities = require("src/entities")
local GameConstants = require("src/game/game_config")
local GameState = require("src/game/game_state")
local EntityUtils = require("src/utils/entity_utils")

local Shooter = {}

-- Shooting system: works for ANY entity with "shooter" tag
function Shooter.update(world)
   world.sys("shooter", function(entity)
      local sx = entity.shoot_dir_x or 0
      local sy = entity.shoot_dir_y or 0

      local cooldown_ready = (entity.shoot_cooldown or 0) == 0
      local wants_to_shoot = sx ~= 0 or sy ~= 0

      -- Check ammo (HP for entities with health_as_ammo, unlimited otherwise)
      -- free_attacks cheat bypasses ammo check
      local has_ammo = true
      local shot_cost = 0

      if entity.health_as_ammo then
         local max_hp = entity.max_hp or 100
         local ratio = entity.max_hp_to_shot_cost_ratio or (GameConstants.Player.max_hp_to_shot_cost_ratio)
         shot_cost = max_hp * ratio
      end

      -- If entity explicitly specifies shot_cost (overriding dynamic calc), use it
      if entity.shot_cost then shot_cost = entity.shot_cost end

      if entity.health_as_ammo and entity.hp and not GameState.cheats.free_attacks then
         has_ammo = entity.hp >= shot_cost
      end

      if wants_to_shoot then
         entity.current_direction = EntityUtils.get_direction_name(sx, sy, entity.current_direction)
         if entity.type == "Player" then
            world.tag(entity, "aiming")
         end
      else
         world.unt(entity, "aiming")
         return
      end

      if (btnp(GameConstants.controls.attack) and entity.type == "Player" and cooldown_ready) or (entity.type == "Enemy" and cooldown_ready) then
         world.tag(entity, "shooting")
      else
         world.unt(entity, "shooting")
      end

      local is_shooting = world.msk(entity).shooting

      if has_ammo and is_shooting then
         -- Trigger attack animation for entities with FSM
         if entity.fsm then entity.fsm:attack() end

         -- Consume ammo if using health (skip if free_attacks cheat active)
         if entity.health_as_ammo and not GameState.cheats.free_attacks then
            -- Clamp HP to minimum 1 so player doesn't die from shooting
            entity.hp = max(1, entity.hp - shot_cost)
            entity.time_since_shot = 0
         end

         -- Spawn projectile
         local projectile_type = entity.projectile_type or "Egg"
         -- Calculate damage dynamically
         local damage = entity.damage
         if not damage and entity.max_hp_to_damage_ratio then
            damage = (entity.max_hp or 100) * entity.max_hp_to_damage_ratio
         end

         Entities.spawn_projectile_from_origin(
            world, entity, sx, sy, projectile_type,
            {
               speed = entity.shot_speed,
               damage = damage,
               knockback = entity.knockback,
               recovery_percent = entity.recovery_percent,
               shot_cost = shot_cost,
               lifetime = (entity.range and entity.shot_speed) and (entity.range / entity.shot_speed) or 60
            }
         )

         entity.shoot_cooldown = entity.shoot_cooldown_duration or 15
      end
   end)()
end

return Shooter
