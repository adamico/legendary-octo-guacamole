local pgui = require("pgui")
local GameOver = SceneManager:addState("GameOver")

local restart_clicked = false
local return_to_title_clicked = false

function GameOver:enteredState() end

function GameOver:exitedState()
   restart_clicked = false
   return_to_title_clicked = false
end

function GameOver:update()
   pgui:refresh()
   local restart_label = "Restart"
   local return_to_title_label = "Return to Title"
   local max_width = max(#restart_label, #return_to_title_label)
   local margin = 3
   local gap = 3
   local buttons = {
      {"button", {text = restart_label, margin = margin, stroke = true}},
      {"button", {text = return_to_title_label, margin = margin, stroke = true}}
   }

   local buttons_stack_pos = vec(
      SCREEN_WIDTH / 2 - max_width * 5 / 2 - margin * 2,
      SCREEN_HEIGHT / 2 - #buttons * 7 / 2 - margin * 2
   )

   local stack = pgui:component("vstack", {
      pos = buttons_stack_pos,
      height = 0,
      box = false,
      stroke = false,
      margin = 0,
      gap = gap,
      contents = buttons,
      color = {16, 12, 7, 0}
   })

   restart_clicked = stack[1]
   return_to_title_clicked = stack[2]

   if return_to_title_clicked then self:gotoState("Title") end
   if restart_clicked then self:gotoState("Play") end
end

function GameOver:draw()
   local game_over = "GAME OVER!"
   camera()
   rectfill(120, 20, 350, 230, 1)
   PrintInGrid(game_over, 13, 4, 7)
   pgui:draw()
end

return GameOver
