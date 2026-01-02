-- Floating Text System: displays damage/heal numbers (Picobloc ECS)
local GameConstants = require("src/game/game_config")
local TextUtils = require("src/utils/text_utils")

local FloatingText = {}

-- Stored reference to ECS world for spawning from callbacks
local current_world = nil

--- @param world ECSWorld
function FloatingText.set_world(world)
   current_world = world
end

-- Configuration defaults
local function get_config()
   return GameConstants.FloatingText
end

--- Spawn a floating text entity
function FloatingText.spawn(x, y, amount, color, sprite_index)
   local config = get_config()

   -- Format text
   local text
   if type(amount) == "number" then
      local display_amount = flr(abs(amount))
      if sprite_index then
         text = "+"..tostring(display_amount)
      else
         text = tostring(display_amount)
      end
   else
      text = tostring(amount)
   end

   -- Random spread
   local offset_x = (rnd(1) - 0.5) * config.spread
   local offset_y = config.offset_y

   -- Spawn Entity
   if current_world then
      current_world:add_entity({
         position = {
            x = x + offset_x,
            y = y + offset_y,
            z = 100 -- High Z to render on top
         },
         floating_text = {
            text = text,
            color = color,
            outline_color = config.outline_color or 0,
            timer = config.duration,
            rise_speed = config.rise_speed,
            fade_start = config.duration - config.fade_duration,
            sprite_index = sprite_index or 0,
         }
      })
   end
end

-- Convenience function to spawn damage text at an entity (by ID)
function FloatingText.spawn_at_entity(entity_id, amount, color, sprite_index)
   if not current_world then return end
   if not current_world:entity_exists(entity_id) then return end

   -- Lookup Position and Size via query_entity
   current_world:query_entity(entity_id, {"position", "size?"},
      function(i, pos, size)
         local x = pos.x[i]
         local y = pos.y[i]

         -- Center based on size if available
         if size and size.width then
            x = x + size.width[i] / 2
         else
            x = x + 8
         end

         FloatingText.spawn(x, y, amount, color, sprite_index)
      end)
end

-- Spawn damage text (defaults to damage color)
function FloatingText.spawn_damage(entity_id, amount)
   local config = get_config()
   FloatingText.spawn_at_entity(entity_id, amount, config.damage_color)
end

-- Spawn heal text (defaults to heal color)
function FloatingText.spawn_heal(entity_id, amount)
   local config = get_config()
   FloatingText.spawn_at_entity(entity_id, amount, config.heal_color)
end

-- Spawn pickup text (defaults to pickup color)
function FloatingText.spawn_pickup(entity_id, text_or_amount, sprite_index)
   local config = get_config()
   FloatingText.spawn_at_entity(entity_id, text_or_amount, config.pickup_color, sprite_index)
end

-- Spawn info/generic text (defaults to white/light color if no specific info color, using pickup as fallback for now or white)
function FloatingText.spawn_info(entity_id, text)
   -- Using pickup color as default for info/purchased messages for now, or could add an info_color to GameConstants
   local config = get_config()
   local color = config.info_color or 7 -- Default to white if not defined
   FloatingText.spawn_at_entity(entity_id, text, color)
end

-- Update all floating text entities
function FloatingText.update(world)
   -- Need 'position' and 'floating_text'
   world:query({"position", "floating_text"}, function(ids, pos, ft)
      for i = ids.first, ids.last do
         -- Update timer
         ft.timer[i] = ft.timer[i] - 1

         -- Move Up
         pos.y[i] = pos.y[i] - ft.rise_speed[i]

         -- Check Expire
         if ft.timer[i] <= 0 then
            world:remove_entity(i)
         end
      end
   end)
end

-- Draw all floating text entities
function FloatingText.draw(world)
   local config = get_config()

   world:query({"position", "floating_text"}, function(ids, pos, ft)
      for i = ids.first, ids.last do
         local text = ft.text[i] -- value type, so it's the string
         local x = pos.x[i]
         local y = pos.y[i]
         local color = ft.color[i]
         local outline = ft.outline_color[i]
         local timer = ft.timer[i]
         local fade = ft.fade_start[i]
         local sprite = ft.sprite_index[i]

         -- Alpha/Fade Logic
         local alpha = 1
         if timer < fade then
            alpha = timer / fade
         end

         if alpha < 0.5 and (t() * 30) % 2 < 1 then
            -- Blink skip
         else
            -- Draw
            local text_width = #text * 4
            local draw_x = x - text_width / 2
            local draw_y = y

            local sprite_width = 0
            if sprite and sprite > 0 then
               sprite_width = config.icon_size + 2
               local isize = config.icon_size
               local ix = draw_x + (config.icon_offset_x or -4)
               local iy = draw_x + (config.icon_offset_y or -1)
               sspr(sprite, 0, 0, 16, 16, ix, iy, isize, isize)
            end

            TextUtils.print_outlined(text, draw_x + sprite_width - 4, draw_y, color, outline)
         end
      end
   end)
end

function FloatingText.clear()
   -- ECS handles cleanup usually, but if we want to force clear?
   -- We'd iterate and delete. For now, rely on timers or scene reset.
   -- Or implement remove_all logic.
end

function FloatingText.count()
   -- Count via query?
   local count = 0
   if current_world then
      current_world:query({"floating_text"}, function(ids)
         count = count + (ids.last - ids.first + 1)
      end)
   end
   return count
end

return FloatingText
