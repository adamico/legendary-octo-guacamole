-- Generic shooting system for ANY entity with "shooter" tag
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
      if entity.health_as_ammo and entity.hp and not GameState.cheats.free_attacks then
         has_ammo = entity.hp >= (entity.shot_cost or 20)
      end

      if wants_to_shoot and has_ammo and cooldown_ready then
         -- Update facing direction to shoot direction (attack direction takes priority)
         entity.current_direction = EntityUtils.get_direction_name(sx, sy, entity.current_direction)

         -- Trigger attack animation for entities with FSM
         if entity.fsm then entity.fsm:attack() end

         -- Consume ammo if using health (skip if free_attacks cheat active)
         if entity.health_as_ammo and not GameState.cheats.free_attacks then
            entity.hp -= (entity.shot_cost or 20)
            entity.time_since_shot = 0
         end

         -- Spawn projectile
         local projectile_type = entity.projectile_type or "Laser"
         Entities.spawn_centered_projectile(
            world, entity, sx, sy, projectile_type,
            {recovery_percent = entity.recovery_percent, shot_cost = entity.shot_cost}
         )

         entity.shoot_cooldown = entity.shoot_cooldown_duration or 15
      end
   end)()
end

return Shooter
