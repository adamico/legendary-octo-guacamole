-- UI system: health bars, debug visualization

local HitboxUtils = require("src/utils/hitbox_utils")
local EntityUtils = require("src/utils/entity_utils")

local UI = {}

-- Draw health bar for an entity
local function draw_health_bar(entity)
   if not entity.hp or entity.type == "Skull" then return end

   local bar_h = 3
   local py = flr(entity.y - 8)

   if entity.health_as_ammo then
      -- Segmented bar for ammo-based entities (Player)
      local shot_cost = entity.shot_cost
      if not shot_cost and entity.max_hp_to_shot_cost_ratio then
         shot_cost = entity.max_hp * entity.max_hp_to_shot_cost_ratio
      end
      shot_cost = shot_cost or 20 -- Fallback

      local base_segments = ceil(entity.max_hp / shot_cost)
      local overheal = entity.overflow_hp or 0
      local overheal_segments = ceil(overheal / shot_cost)
      local total_segments = base_segments + overheal_segments
      local seg_w = 6
      local gap = 1
      local total_w = (seg_w + gap) * total_segments - gap
      local px = flr(entity.x + (entity.width or 16) / 2 - total_w / 2)

      -- Draw base HP segments (green)
      for i = 0, base_segments - 1 do
         local start_x = px + i * (seg_w + gap)
         local segment_hp = min(shot_cost, max(0, entity.hp - (i * shot_cost)))

         if segment_hp >= shot_cost then
            rectfill(start_x, py, start_x + seg_w - 1, py + bar_h, 11) -- Full (green)
         elseif segment_hp > 0 then
            rectfill(start_x, py, start_x + seg_w - 1, py + bar_h, 8)  -- Empty (dark)
            local fill_w = ceil((segment_hp / shot_cost) * seg_w)
            rectfill(start_x, py, start_x + fill_w - 1, py + bar_h, 9) -- Partial (orange)
         else
            rectfill(start_x, py, start_x + seg_w - 1, py + bar_h, 8)  -- Empty (dark)
         end
      end

      -- Draw overheal segments (light blue)
      for i = 0, overheal_segments - 1 do
         local start_x = px + (base_segments + i) * (seg_w + gap)
         local segment_overheal = min(shot_cost, max(0, overheal - (i * shot_cost)))

         if segment_overheal >= shot_cost then
            rectfill(start_x, py, start_x + seg_w - 1, py + bar_h, 12)  -- Full (light blue)
         elseif segment_overheal > 0 then
            rectfill(start_x, py, start_x + seg_w - 1, py + bar_h, 8)   -- Empty (dark)
            local fill_w = ceil((segment_overheal / shot_cost) * seg_w)
            rectfill(start_x, py, start_x + fill_w - 1, py + bar_h, 12) -- Partial (light blue)
         end
      end
   else
      -- Continuous bar for standard entities (Enemies)
      local total_w = entity.width or 16
      local px = flr(entity.x + (entity.width or 16) / 2 - total_w / 2)

      -- Background
      rectfill(px, py, px + total_w - 1, py + bar_h, 8)

      -- Foreground
      if entity.max_hp and entity.max_hp > 0 then
         local fill_w = ceil((entity.hp / entity.max_hp) * total_w)
         if fill_w > 0 then
            rectfill(px, py, px + fill_w - 1, py + bar_h, 11)
         end
      end
   end
end

-- Draw debug hitbox for an entity
local function draw_hitbox(entity)
   local hb = HitboxUtils.get_hitbox(entity)
   rect(hb.x, hb.y, hb.x + hb.w, hb.y + hb.h, 8)
end

-- Draw aim line for an entity
local function draw_aim_line(entity)
   local cx, cy = EntityUtils.get_center(entity)
   local aim_line = {
      x1 = cx,
      y1 = cy,
      x2 = cx + entity.range * entity.shoot_dir_x,
      y2 = cy + entity.range * entity.shoot_dir_y,
   }
   fillp(0x5A5A)
   line(aim_line.x1, aim_line.y1, aim_line.x2, aim_line.y2, 8)
   fillp()
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

function UI.draw_aim_lines(world)
   world.sys("aiming", draw_aim_line)()
end

return UI
