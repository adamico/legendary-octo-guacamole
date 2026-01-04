local pgui = require("lib/pgui")
local SceneManager = require("src/scenes/manager")
local MenuNav = require("src/ui/menu_nav")
local Victory = SceneManager:addState("Victory")

local restart_clicked = false
local return_to_title_clicked = false
local fprint           = function(...)
	require("src/utils/text_utils").fprint(simple_font, ...)
end
-- Menu navigation
local nav = MenuNav.new(2)

function Victory:enteredState()
   Log.trace("Entered Victory scene")
   -- Reset all GFX state to ensure clean visuals
   pal()           -- Reset color remaps
   palt()          -- Reset transparency (color 0 is transparent for spr/map)
   camera()        -- Reset camera to 0,0
   poke(0x550b, 0) -- Reset pen palette row to 0 (crucial for lighting fix)
   -- Reset navigation state
   nav:reset()
end

function Victory:exitedState()
   restart_clicked = false
   return_to_title_clicked = false
   nav:reset()
end

function Victory:update()
   pgui:refresh()

   -- Update navigation and check for confirm
   local confirmed = nav:update(pgui)

   local restart_label = "Restart"
   local return_to_title_label = "Return to Title"
   local max_width = max(#restart_label, #return_to_title_label)
   local margin = 4
   local gap = 4

   -- Calculate button positions BEFORE creating vstack
   local buttons_stack_pos = vec(
      SCREEN_WIDTH / 2 - (max_width * 5 + margin * 2) / 2,
      SCREEN_HEIGHT / 2 + 10
   )

   nav:calculate_button_rects(buttons_stack_pos, nav.num_buttons, max_width, margin, gap)
   nav:apply_hover(pgui)

   -- Using safer standard colors: 5 (dark grey), 12 (cyan), 7 (white), 0 (black)
   local buttons = {
      {"button", {text = restart_label, margin = margin, stroke = true, color = {5, 12, 7, 0}}},
      {"button", {text = return_to_title_label, margin = margin, stroke = true, color = {5, 12, 7, 0}}}
   }

   local stack = pgui:component("vstack", {
      pos = buttons_stack_pos,
      height = 0,
      box = false,
      stroke = false,
      margin = 0,
      gap = gap,
      contents = buttons,
      color = {0, 0, 0, 0}
   })

   -- Check button activations (mouse click or keyboard confirm)
   restart_clicked = nav:is_activated(1, stack[1], confirmed)
   return_to_title_clicked = nav:is_activated(2, stack[2], confirmed)

   if return_to_title_clicked then self:gotoState("Title") end
   if restart_clicked then self:gotoState("Play") end
end

function Victory:draw()
   -- Dark red/black background for game over
   cls(0)
   rectfill(0, SCREEN_HEIGHT / 2 - 40, SCREEN_WIDTH, SCREEN_HEIGHT / 2 + 60, 1) -- Dark blue/grey band

   local victory = "Victory!"
   local font_scale = 2
   local text_x = SCREEN_WIDTH / 2 - (#victory * 5 * font_scale) / 2
   local text_y = SCREEN_HEIGHT / 2 - 20

   -- Shadow/Outline for text
   fprint(victory, text_x + 1, text_y + 1, 21, font_scale) -- Black shadow
   fprint(victory, text_x, text_y, 8, font_scale) -- Red text

   pgui:draw()
   nav:draw_arrow(pgui)
end

return Victory
