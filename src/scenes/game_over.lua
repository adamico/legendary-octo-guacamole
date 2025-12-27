local pgui = require("lib/pgui")
local SceneManager = require("src/scenes/manager")
local GameOver = SceneManager:addState("GameOver")

local restart_clicked = false
local return_to_title_clicked = false

function GameOver:enteredState()
   Log.trace("Entered GameOver scene")
   -- Reset all GFX state to ensure clean visuals
   pal()           -- Reset color remaps
   palt()          -- Reset transparency (color 0 is transparent for spr/map)
   camera()        -- Reset camera to 0,0
   poke(0x550b, 0) -- Reset pen palette row to 0 (crucial for lighting fix)
end

function GameOver:exitedState()
   restart_clicked = false
   return_to_title_clicked = false
end

function GameOver:update()
   pgui:refresh()

   local restart_label = "Restart"
   local return_to_title_label = "Return to Title"
   local max_width = max(#restart_label, #return_to_title_label)
   local margin = 4
   local gap = 4

   -- Using safer standard colors: 5 (dark grey), 12 (cyan), 7 (white), 0 (black)
   local buttons = {
      {"button", {text = restart_label, margin = margin, stroke = true, color = {5, 12, 7, 0}}},
      {"button", {text = return_to_title_label, margin = margin, stroke = true, color = {5, 12, 7, 0}}}
   }

   local buttons_stack_pos = vec(
      SCREEN_WIDTH / 2 - (max_width * 5 + margin * 2) / 2,
      SCREEN_HEIGHT / 2 + 10 -- Positioned slightly below center
   )

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

   restart_clicked = stack[1]
   return_to_title_clicked = stack[2]

   if return_to_title_clicked then self:gotoState("Title") end
   if restart_clicked then self:gotoState("Play") end
end

function GameOver:draw()
   -- Dark red/black background for game over
   cls(0)
   rectfill(0, SCREEN_HEIGHT / 2 - 40, SCREEN_WIDTH, SCREEN_HEIGHT / 2 + 60, 1) -- Dark blue/grey band

   local game_over = "GAME OVER"
   local text_x = SCREEN_WIDTH / 2 - (#game_over * 5) / 2
   local text_y = SCREEN_HEIGHT / 2 - 20

   -- Shadow/Outline for text
   print(game_over, text_x + 1, text_y + 1, 0)
   print(game_over, text_x, text_y, 8) -- Red text

   pgui:draw()
end

return GameOver
