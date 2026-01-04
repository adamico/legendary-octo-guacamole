local pgui = require("lib/pgui")
local SceneManager = require("src/scenes/manager")
local MenuNav = require("src/ui/menu_nav")
local GameOver = SceneManager:addState("GameOver")

local restart_clicked = false
local return_to_title_clicked = false
local fprint           = function(...)
	require("src/utils/text_utils").fprint(simple_font, ...)
end
-- Menu navigation
local nav = MenuNav.new(2)

function GameOver:enteredState()
   Log.trace("Entered GameOver scene")
   -- Reset all GFX state to ensure clean visuals
   pal()           -- Reset color remaps
   palt()          -- Reset transparency (color 0 is transparent for spr/map)
   camera()        -- Reset camera to 0,0
   poke(0x550b, 0) -- Reset pen palette row to 0 (crucial for lighting fix)
   -- Reset navigation state
   nav:reset()
   fetch(CARTPATH.."sfx/game_over.sfx"):poke(0x80000) -- load 256k into 0x80000..0xbffff
   music(0, nil, nil, 0x80000) -- play music using 0x80000 as the audio base address
end

function GameOver:exitedState()
   restart_clicked = false
   return_to_title_clicked = false
   nav:reset()
end

function GameOver:update()
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
   nav:play_hover_sfx(pgui)

   -- Using safer standard colors: 5 (dark grey), 12 (cyan), 7 (white), 0 (black)
   -- Pad labels to same width for uniform buttons
   local buttons = {
      {"button", {text = MenuNav.pad_label(restart_label, max_width), margin = margin, stroke = true, color = {5, 12, 7, 0}}},
      {"button", {text = MenuNav.pad_label(return_to_title_label, max_width), margin = margin, stroke = true, color = {5, 12, 7, 0}}}
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

function GameOver:draw()
   -- Dark red/black background for game over
   cls(0)
   rectfill(0, SCREEN_HEIGHT / 2 - 40, SCREEN_WIDTH, SCREEN_HEIGHT / 2 + 60, 1) -- Dark blue/grey band

   local game_over = "GAME OVER"
   local font_scale = 2
   local text_x = SCREEN_WIDTH / 2 - (#game_over * 5 * font_scale) / 2
   local text_y = SCREEN_HEIGHT / 2 - 20

   -- Shadow/Outline for text
   fprint(game_over, text_x + 1, text_y + 1, 21, font_scale) -- Black shadow
   fprint(game_over, text_x, text_y, 8, font_scale) -- Red text

   pgui:draw()
   nav:draw_arrow(pgui)
end

return GameOver
