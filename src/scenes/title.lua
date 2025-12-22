local pgui             = require("pgui")
local Title            = SceneManager:addState("Title")

local new_game_clicked = false
local quit_clicked     = false

function Title:enteredState()
	Log.trace("Entered Title scene")
end

function Title:update()
	pgui:refresh()
	local new_game_label    = "New Game"
	local quit_label        = "Quit"
	local max_width         = max(#new_game_label, #quit_label)
	local margin            = 3
	local gap               = 3
	local contents          = {
		{"button", {text = new_game_label, margin = margin, stroke = true}},
		{"button", {text = quit_label, margin = margin, stroke = true}}
	}
	local buttons_stack_pos = vec(SCREEN_WIDTH / 2 - max_width * 5 / 2 - margin * 2,
		SCREEN_HEIGHT / 2 - #contents * 7 / 2 - margin * 2)
	local stack             = pgui:component("vstack", {
		pos      = buttons_stack_pos,
		height   = 0,
		box      = false,
		stroke   = false,
		margin   = 0,
		gap      = gap,
		contents = contents,
		color    = {16, 12, 7, 0}
	})

	new_game_clicked        = stack[1]
	quit_clicked            = stack[2]

	if new_game_clicked then self:gotoState("Stage1") end
	if quit_clicked then print("Clicked Quit", 0, 0, 7) end
end

function Title:exitedState()
	new_game_clicked = false
	quit_clicked = false
	Log.trace("Exited Title scene")
end

function Title:draw()
	cls(1)
	camera()
	local game_title_label = GAME_TITLE
	print(game_title_label, SCREEN_WIDTH / 2 - #game_title_label * 5 / 2, 10, 7)
	pgui:draw()
end

return Title
