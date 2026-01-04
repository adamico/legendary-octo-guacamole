local SceneManager = require("src/scenes/manager")
local Pools = require("src/game/config/level_up")

local LevelUp = SceneManager:addState("LevelUp")

local player = nil
local bonuses = {}
local selected_index = 2 -- Middle card by default

function LevelUp:pushedState(player_entity)
   Log.trace("Entered LevelUp state")
   player = player_entity
   bonuses = {}

   -- Pick one random bonus from each pool
   add(bonuses, rnd(Pools.Player))
   add(bonuses, rnd(Pools.Egg))
   add(bonuses, rnd(Pools.Chick))

   selected_index = 2 -- Reset to center
   -- REFACTOR: Use SoundManager.play("level_up") or similar
   sfx(5) -- level up sound
end

function LevelUp:update()
   if btnp(0) then selected_index = math.max(1, selected_index - 1) end
   if btnp(1) then selected_index = math.min(3, selected_index + 1) end

   if btnp(4) or btnp(5) then -- O or X to select
      local bonus = bonuses[selected_index]
      if bonus then
         Log.info("Selected bonus: "..bonus.name)
         bonus.apply(player)
         self:popState()
      end
   end
end

function LevelUp:draw()
   -- Draw opaque background overlay (dithered or solid)
   -- Using solid dark color 5 (Dark Gray) for now as requested
   rectfill(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, 5)

   -- Title
   local title = "LEVEL UP!"
   print(title, SCREEN_WIDTH / 2 - (#title * 4), 20, 7)

   -- Draw Cards
   local card_w, card_h = 120, 160
   local gap = 16
   local start_x = (SCREEN_WIDTH - (3 * card_w + 2 * gap)) / 2
   local start_y = 50

   for i = 1, 3 do
      local bonus = bonuses[i]
      local x = start_x + (i - 1) * (card_w + gap)
      local y = start_y

      -- Card Background
      local is_selected = (i == selected_index)
      local bg_color = 0                           -- Black card bg
      local border_color = is_selected and 12 or 1 -- Cyan if selected, Blue/White if not

      rectfill(x, y, x + card_w, y + card_h, bg_color)
      rect(x, y, x + card_w, y + card_h, border_color)

      -- Content
      local cx = x + card_w / 2

      -- Category
      local cat_color = 6 -- Grey
      print(bonus.category, cx - (#bonus.category * 4) / 2, y + 10, cat_color)

      -- Icon Placeholder (Circle)
      circ(cx, y + 50, 20, is_selected and 12 or 1)

      -- Name
      local name_color = is_selected and 7 or 6
      print(bonus.name, cx - (#bonus.name * 4) / 2, y + 90, name_color)

      -- Description (simple wrap)
      local desc_color = 6
      print(bonus.description, cx - (#bonus.description * 4) / 2, y + 110, desc_color)
   end

   -- Instruction
   local instr = "Select a Bonus"
   if (time() * 2) % 2 < 1 then
      print(instr, SCREEN_WIDTH / 2 - (#instr * 4) / 2, 240, 7)
   end
end

return LevelUp
