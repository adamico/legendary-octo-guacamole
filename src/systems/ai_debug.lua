local PathFollow = require("src/ai/primitives/path_follow")
local HitboxUtils = require("src/utils/hitbox_utils")
local EntityProxy = require("src/utils/entity_proxy")

local AIDebug = {}

function AIDebug.draw(world)
   world:query({"minion", "minion_type"}, function(ids, minions, types)
      for i = 0, ids.count - 1 do
         local id = ids[i]
         local type_val = types.value[i]

         if type_val == "Chick" then
            local e = EntityProxy.new(world, id)

            -- Draw current path (green if exists)
            PathFollow.debug_draw(e, 11) -- Green path

            -- Draw FSM state above chick
            local state_name = e.chick_fsm and e.chick_fsm.current or "none"
            print(state_name, e.x - 16, e.y - 32, 7) -- White state name (higher up)

            -- Draw attack range circle (light blue - melee range)
            local attack_range = e.attack_range or 20
            circ(e.x + 8, e.y + 8, attack_range, 12) -- Light blue attack range

            -- Draw line to chase target
            if e.chase_target then
               local hb = HitboxUtils.get_hitbox(e)
               local ex, ey = hb.x + hb.w / 2, hb.y + hb.h / 2
               local thb = HitboxUtils.get_hitbox(e.chase_target)
               local tx, ty = thb.x + thb.w / 2, thb.y + thb.h / 2

               -- Calculate distance
               local dx, dy = tx - ex, ty - ey
               local dist = sqrt(dx * dx + dy * dy)

               -- Check if using direct fallback (no valid path)
               local has_path = e.path_state and e.path_state.path and #e.path_state.path > 0
               if has_path then
                  line(ex, ey, tx, ty, 11)              -- Green = has path
                  circfill(tx, ty, 4, 11)               -- Target circle
               else
                  line(ex, ey, tx, ty, 8)               -- Red = NO PATH (direct fallback!)
                  circfill(tx, ty, 4, 8)                -- Red target
                  print("NO PATH", ex - 16, ey - 16, 8) -- Alert text
               end

               -- Show distance vs attack range
               local in_range = dist < attack_range
               local range_text = string.format("d:%.0f/%.0f", dist, attack_range)
               print(range_text, ex - 20, ey - 32, in_range and 11 or 8)
            end
         end
      end
   end)
end

return AIDebug
