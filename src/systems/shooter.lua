local Entities = require("src/entities")
local GameConstants = require("src/game/game_config")
local GameState = require("src/game/game_state")
local EntityUtils = require("src/utils/entity_utils")
local Input = require("src/input")

local Shooter = {}

--- Shooting system: works for ANY entity with "shooter" tags
--- @param world ECSWorld
function Shooter.update(world)
   world:query({
      "shooter", "position", "direction?", "health?",
      "timers?", "fsm?", "projectile_type?", "velocity?",
      "controllable?", "player?"
   }, function(ids, shooter, pos, dir, health, timers, fsm, proj_type, vel, controllable, player_tag)
      for i = ids.first, ids.last do
         local id = ids[i]

         -- Extract Direction: use Input.shoot_dir for player, dir component for enemies
         local sx = 0
         local sy = 0
         local is_player = player_tag ~= nil
         if is_player then
            -- Player uses dedicated aim controls
            sx = Input.shoot_dir.x
            sy = Input.shoot_dir.y
         elseif dir then
            -- Enemies use their direction component
            sx = dir.dir_x[i]
            sy = dir.dir_y[i]
         end

         -- Cooldown check
         local cooldown = timers and timers.shoot_cooldown[i] or 0
         local cooldown_ready = cooldown == 0
         local wants_to_shoot = (sx ~= 0 or sy ~= 0)

         -- Ammo check
         local has_ammo = true
         local shot_cost = 0
         local health_as_ammo = shooter.health_as_ammo[i]

         if health_as_ammo and health then
            -- Calculate cost
            local max_hp = health.max_hp[i]
            local ratio = shooter.max_hp_to_shot_cost_ratio[i]
            if ratio == 0 then ratio = GameConstants.Player.max_hp_to_shot_cost_ratio end
            shot_cost = max_hp * ratio

            -- Check HP
            local current_hp = health.hp[i]
            if not GameState.cheats.free_attacks then
               has_ammo = current_hp >= shot_cost
            end
         end

         if wants_to_shoot then
            -- Update facing direction lookup string if needed
            local current_facing = dir and dir.facing[i]
            local new_facing = EntityUtils.get_direction_name(sx, sy, current_facing)
            if dir then dir.facing[i] = new_facing end

            -- Add "aiming" tag logic if needed (ECS usually separate state, but we can mimic tag)
            if player_tag then
               -- Using aiming tag for player visual state
               -- Implementation note: Picobloc doesn't have instant tag like eggs.
               -- We'd need to add/remove component. Skipping purely visual transient tag for now unless critical.
            end
         end

         -- Input check
         local attack_pressed = is_player and btnp(GameConstants.controls.attack)
         -- Enemy shoots if cooldown ready (and typically if in range/aggro, managed by AI setting shoot_dir)
         local enemy_shoot = not is_player and cooldown_ready and wants_to_shoot

         local trigger_shot = (attack_pressed and cooldown_ready) or enemy_shoot

         if trigger_shot and has_ammo then
            -- Trigger attack animation
            if fsm then
               local fsm_instance = fsm.value[i]
               if fsm_instance and fsm_instance.attack then fsm_instance:attack() end
            end

            -- Consume ammo
            if health_as_ammo and not GameState.cheats.free_attacks then
               health.hp[i] = max(1, health.hp[i] - shot_cost)
               shooter.time_since_shot[i] = 0
            end

            -- Spawn projectile
            local p_type = proj_type and proj_type.value[i] or shooter.projectile_type[i] or "Egg"

            -- Prepare temporary proxy for spawn function
            -- Entities.spawn_projectile_from_origin expects an entity table with x, y, etc.
            local proxy = {
               x = pos.x[i],
               y = pos.y[i],
               z = pos.z[i],
               width = 16, -- Default if no size component
               height = 16,
               projectile_origin_x = shooter.projectile_origin_x[i],
               projectile_origin_y = shooter.projectile_origin_y[i],
               projectile_origin_z = shooter.projectile_origin_z[i],
               shot_speed = shooter.shot_speed[i],
               knockback = shooter.knockback[i],
               recovery_percent = shooter.recovery_percent[i],
               impact_damage = shooter.impact_damage[i],
               drain_damage = shooter.drain_damage[i],
               drain_heal = shooter.drain_heal[i],
               hatch_time = shooter.hatch_time[i],
               range = shooter.range[i],
            }

            -- Add size if available
            -- We didn't query size, but spawn_from_origin defaults to 16.
            -- Add damage logic
            local damage = shooter.impact_damage[i]
            -- Calc damage logic from original...
            if damage == 0 and shooter.max_hp_to_damage_ratio[i] > 0 and health then
               damage = health.max_hp[i] * shooter.max_hp_to_damage_ratio[i]
            end

            Entities.spawn_projectile_from_origin(
               world, proxy, sx, sy, p_type,
               {
                  speed = shooter.shot_speed[i],
                  damage = damage,
                  knockback = shooter.knockback[i],
                  recovery_percent = shooter.recovery_percent[i],
                  shot_cost = shot_cost,
                  lifetime = (shooter.range[i] > 0 and shooter.shot_speed[i] > 0)
                     and (shooter.range[i] / shooter.shot_speed[i]) or 60,

                  impact_damage = shooter.impact_damage[i],
                  drain_damage = shooter.drain_damage[i],
                  drain_heal = shooter.drain_heal[i],
                  hatch_time = shooter.hatch_time[i],

                  egg_slow_duration = 60, -- Default
                  egg_slow_factor = 0.5,
               }
            )

            -- Reset cooldown
            local duration = shooter.shoot_cooldown_duration[i]
            if duration == 0 then duration = 15 end
            if timers then timers.shoot_cooldown[i] = duration end
         end
      end
   end)
end

return Shooter
