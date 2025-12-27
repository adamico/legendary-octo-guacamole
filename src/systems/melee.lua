-- Melee attack system
local GameConstants = require("src/constants")
local Render = require("src/systems/rendering")
local EntityUtils = require("src/utils/entity_utils")

local Melee = {}

function Melee.update(world)
   -- Only players can melee for now
   world.sys("player,controllable", function(player)
      -- Check cooldown (free_attacks cheat bypasses cooldown)
      if not GameConstants.cheats.free_attacks and player.melee_cooldown and player.melee_cooldown > 0 then return end

      local input_pressed = btn(GameConstants.controls.melee)

      -- Health gating: Only allowed if HP < max_hp / 5 (one segment)
      -- free_attacks cheat bypasses this check
      local health_threshold = player.max_hp / 5
      local low_health = player.hp < health_threshold or GameConstants.cheats.free_attacks

      if input_pressed and low_health then
         -- Pay health cost (skip if free_attacks cheat active)
         if not GameConstants.cheats.free_attacks then
            local cost = player.melee_cost or 10
            player.hp = math.max(1, player.hp - cost)
         end

         -- Set cooldown
         player.melee_cooldown = GameConstants.Player.melee_cooldown

         -- Calculate spawn position and rotation
         local range = GameConstants.Player.melee_range

         -- Use facing direction (persistent) per user request
         local dir = player.current_direction or "down"
         local dx, dy = EntityUtils.get_direction_vector(dir)
         local offset_x = GameConstants.Player.melee_offsets[dir][1]
         local offset_y = GameConstants.Player.melee_offsets[dir][2]
         local spawn_x = player.x + dx * range + offset_x
         local spawn_y = player.y + dy * range + offset_y

         -- Determine rotation angle (0=Up, 90=Right, 180=Down, 270=Left)
         local angle = 0
         if math.abs(dx) > math.abs(dy) then
            if dx > 0 then angle = 90 else angle = 270 end
         else
            if dy > 0 then angle = 180 else angle = 0 end
         end

         -- Calculate damage based on missing health
         local damage = math.floor((player.max_hp - player.hp) / 4)
         damage = math.max(1, damage)

         -- Spawn MeleeHitbox
         local hitbox = {
            type = "MeleeHitbox",
            -- Initial position
            x = spawn_x,
            y = spawn_y,
            -- Store relative offset for position syncing
            offset_x = dx * range + offset_x,
            offset_y = dy * range + offset_y,

            width = GameConstants.Player.melee_width,
            height = GameConstants.Player.melee_height,
            -- Visual properties
            sprite_index = GameConstants.Player.melee_sprite,
            rotation_angle = angle,
            outline_color = 1, -- White outline? Match player?
            -- System tags (added 'melee_hitbox' tag for syncing)
            lifespan = GameConstants.Player.melee_duration,
            owner_entity = player,
            melee_damage = damage,
            -- Adjust hitbox centering
            hitbox_width = GameConstants.Player.melee_hitboxes[dir].w,
            hitbox_height = GameConstants.Player.melee_hitboxes[dir].h,
            hitbox_offset_x = GameConstants.Player.melee_hitboxes[dir].ox,
            hitbox_offset_y = GameConstants.Player.melee_hitboxes[dir].oy,
            -- Track enemies already hit (prevents multi-proc on same enemy)
            hit_list = {}
         }

         EntityUtils.spawn_entity(world, "collidable,drawable,timers,middleground,melee_hitbox", hitbox)
      end
   end)()

   -- Sync melee hitbox positions with their owners
   world.sys("melee_hitbox", function(hitbox)
      local owner = hitbox.owner_entity
      if owner and owner.x then
         hitbox.x = owner.x + (hitbox.offset_x or 0)
         hitbox.y = owner.y + (hitbox.offset_y or 0)
      else
         -- Owner dead/gone? Delete hitbox
         world.del(hitbox)
      end
   end)()
end

return Melee
