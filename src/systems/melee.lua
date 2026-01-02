-- Melee attack system
local GameConstants = require("src/game/game_config")
local GameState = require("src/game/game_state")
local EntityUtils = require("src/utils/entity_utils")

local Melee = {}

--- Melee update function
--- @param world ECSWorld
function Melee.update(world)
   -- Only players can melee for now
   world:query({"player", "melee", "position", "direction", "health?", "timers?", "fsm?"},
      function(ids, player, melee, pos, dir, health, timers, fsm)
         for i = ids.first, ids.last do
            local id = ids[i]

            -- Check cooldown (free_attacks cheat bypasses cooldown)
            -- Note: aiming tag equivalent check skipped or assumed valid for player
            if not GameState.cheats.free_attacks and timers and timers.melee_cooldown[i] > 0 then
               -- Check next entity
            else
               local input_pressed = btn(GameConstants.controls.attack)

               -- Health gating
               local max_hp = health and health.max_hp[i] or 100
               local current_hp = health and health.hp[i] or 100

               local health_threshold = max_hp / 5
               local low_health = current_hp < health_threshold or GameState.cheats.free_attacks

               if input_pressed and low_health then
                  -- Trigger animation
                  local fsm_instance = fsm and fsm.value[i]
                  if fsm_instance and fsm_instance.attack then fsm_instance:attack() end

                  -- Pay health cost
                  if not GameState.cheats.free_attacks then
                     local cost = melee.melee_cost[i]
                     -- Default cost if 0? Assuming component has valid data
                     if cost == 0 then cost = 10 end

                     if health then
                        health.hp[i] = math.max(1, current_hp - cost)
                     end
                  end

                  -- Set cooldown
                  if timers then
                     timers.melee_cooldown[i] = GameConstants.Player.melee_cooldown
                  end

                  -- Calculate spawn pos
                  local range = GameConstants.Player.melee_range
                  local facing = dir.facing[i] or "down"
                  local dx, dy = EntityUtils.get_direction_vector(facing)
                  local hb_config = GameConstants.Player.melee_hitboxes[facing]
                  local spawn_x = pos.x[i] + dx * range + hb_config.ox
                  local spawn_y = pos.y[i] + dy * range + hb_config.oy

                  -- Rotation angle
                  local angle = 0
                  if math.abs(dx) > math.abs(dy) then
                     if dx > 0 then angle = 90 else angle = 270 end
                  else
                     if dy > 0 then angle = 180 else angle = 0 end
                  end

                  -- Damage calc
                  local damage = math.floor((max_hp - current_hp) / 4)
                  local bonus = melee.melee_bonus_damage[i]
                  damage = math.max(1, damage) + bonus

                  -- Spawn MeleeHitbox via world:add_entity
                  local hitbox_id = world:add_entity({
                     -- Tags
                     collidable = {
                        hitboxes = {
                           w = hb_config.w,
                           h = hb_config.h,
                           ox = 0, -- Offsets handled by position
                           oy = 0,
                        },
                        map_collidable = false,
                     },
                     drawable = {
                        sprite_index = GameConstants.Player.melee_sprite,
                        outline_color = {value = 1}, -- Palette index
                        sort_offset_y = 0,
                        rotation = angle,
                     },
                     timers = {
                        lifespan = GameConstants.Player.melee_duration,
                     },
                     middleground = true,
                     melee_hitbox = true, -- Tag for sync system below

                     position = {
                        x = spawn_x,
                        y = spawn_y,
                        z = pos.z[i], -- Inherit Z
                     },
                     size = {
                        width = GameConstants.Player.melee_width,
                        height = GameConstants.Player.melee_height,
                     },

                     -- Custom component for sync data?
                     -- Or just reuse existing components or add a custom temporary component?
                     -- Components.lua doesn't have `melee_sync`.
                     -- We can store offset in `velocity` (sub_x/sub_y) or just recalc?
                     -- Original code stored `offset_x`, `offset_y`, `owner_entity`.
                     -- We need to store `owner_id`.

                     -- Using `projectile_owner` component for owner ID?
                     -- It has `owner` field which is "value". We can store ID there.
                     projectile_owner = {
                        owner = {value = id}, -- Store ID as value
                     },

                     -- Store offsets in `velocity` to avoid new component?
                     -- `velocity.sub_x`, `sub_y` are f64.
                     -- But `melee_hitbox` doesn't move via physics usually?
                     -- Actually let's use `velocity` fields `vel_x`, `vel_y` to store offset!
                     -- And ensure it doesn't have `velocity` tag in system query so Physics doesn't move it?
                     -- Physics queries `velocity`.
                     -- So if we add velocity component, Physics will move it.
                     -- BUT we can set friction to 0, accel to 0.
                     -- However, we manually set position in sync system.
                     -- Let's stick to using a Lua table for custom data if needed, but Picobloc components are strict.
                     -- Adding "melee_sync" component to components.lua would be cleanest, but I don't want to modify components.lua again right now if avoidable.
                     -- Use `projectile_combat` damage? Yes.
                     projectile_combat = {
                        damage = damage,
                     },

                     -- For offset, we can use `direction` component which is unused for hitbox visual logic usually?
                     -- Or just recalculate from owner pos + facing every frame?
                     -- But owner might move.
                     -- Let's store offset in `velocity` `knockback_vel_x/y`? A bit hacky.
                     -- Let's just USE `velocity` component but NOT give it a `velocity` TAG?
                     -- Components ARE the tags in Picobloc effectively.
                     -- If it has `velocity` component, Physics updates it.

                     -- WAIT: Physics system queries `velocity` AND `position`.
                     -- If we add `velocity` component, Physics runs.
                     -- If we want to store data without Physics moving it, we need another component.
                     -- `direction` component has dir_x, dir_y. Physics uses it for input direction.
                     -- This hitbox doesn't use input.
                     -- So we can store offsets in `dir_x`, `dir_y` of `direction` component!
                     -- And since `acceleration` component is missing, Physics won't apply acceleration.
                     -- Physics `apply_vel_logic` applies vel.
                     -- So we just don't add `velocity` component.
                     -- We add `direction` component to store offsets.
                     direction = {
                        dir_x = dx * range + hb_config.ox,
                        dir_y = dy * range + hb_config.oy,
                     },
                  })
               end
            end
         end
      end)

   -- Sync melee hitbox positions with their owners
   world:query({"melee_hitbox", "projectile_owner", "position", "direction"},
      function(ids, nav_tag, owner_c, pos, dir_offset)
         for i = ids.first, ids.last do
            local id = ids[i]
            local owner_id = owner_c.owner[i] and owner_c.owner[i].value -- stored as table/value

            if not owner_id then
               -- Should not happen, but cleanup
               world:remove_entity(id)
            else
               local owner_exists = world:entity_exists(owner_id)
               if owner_exists then
                  -- Get owner position
                  -- Need random access to owner components.
                  -- Using world:query_entity leads to nested queries which Picobloc supports (depth check).
                  -- Efficient enough for 1-2 hitboxes.

                  world:query_entity(owner_id, {"position"}, function(o_idx, o_pos)
                     -- Update hitbox position
                     pos.x[i] = o_pos.x[o_idx] + dir_offset.dir_x[i] -- retrieval from 'direction' storage
                     pos.y[i] = o_pos.y[o_idx] + dir_offset.dir_y[i]
                  end)
               else
                  -- Owner dead/gone
                  -- Remove hitbox
                  world:remove_entity(id)
               end
            end
         end
      end)
end

return Melee
