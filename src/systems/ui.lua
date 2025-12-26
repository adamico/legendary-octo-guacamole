-- UI system: health bars, debug visualization

local HitboxUtils = require("src/utils/hitbox_utils")

local UI = {}

-- Draw health bar for an entity
local function draw_health_bar(entity)
   if not entity.hp or entity.type == "Skull" then return end

   local shot_cost = entity.shot_cost or 20
   local segments = ceil(entity.max_hp / shot_cost)
   local seg_w = 6
   local bar_h = 3
   local gap = 1
   local total_w = (seg_w + gap) * segments - gap
   local px = flr(entity.x + (entity.width or 16) / 2 - total_w / 2)
   local py = flr(entity.y - 8)

   for i = 0, segments - 1 do
      local start_x = px + i * (seg_w + gap)
      local segment_hp = min(shot_cost, max(0, entity.hp - (i * shot_cost)))

      if segment_hp >= shot_cost then
         rectfill(start_x, py, start_x + seg_w - 1, py + bar_h, 11)
      elseif segment_hp > 0 then
         rectfill(start_x, py, start_x + seg_w - 1, py + bar_h, 8)
         local fill_w = ceil((segment_hp / shot_cost) * seg_w)
         rectfill(start_x, py, start_x + fill_w - 1, py + bar_h, 9)
      else
         rectfill(start_x, py, start_x + seg_w - 1, py + bar_h, 8)
      end
   end
end

-- Draw debug hitbox for an entity
local function draw_hitbox(entity)
   local hb = HitboxUtils.get_hitbox(entity)
   rect(hb.x, hb.y, hb.x + hb.w, hb.y + hb.h, 8)
end

-- Draw health bars for all entities with health
-- @param world - ECS world
function UI.draw_health_bars(world)
   world.sys("health", draw_health_bar)()
end

-- Draw debug hitboxes for all collidable entities
-- @param world - ECS world
function UI.draw_hitboxes(world)
   world.sys("collidable", draw_hitbox)()
end

return UI
