local pgui             = require("lib/pgui")
local SceneManager     = require("src/scenes/manager")
local Title            = SceneManager:addState("Title")

local new_game_clicked = false
local quit_clicked     = false
local help_clicked     = false
local show_help        = false

-- Keyboard navigation state
local selected_index   = 1
local num_buttons      = 3
local button_rects     = {} -- Store button positions/sizes for visual highlight
local using_keyboard   = true -- Track input mode: keyboard or mouse
local last_mouse_x     = 0
local last_mouse_y     = 0

function Title:enteredState()
	Log.trace("Entered Title scene")
	pal()
	palt()
	camera()
	poke(0x550b, 0)
	show_help = false
	selected_index = 1
	button_rects = {}
	using_keyboard = true
	last_mouse_x = 0
	last_mouse_y = 0
end

-- Check if any navigation input is pressed
local function nav_up()
	return btnp(2) or btnp(10) -- up on either d-pad
end

local function nav_down()
	return btnp(3) or btnp(11) -- down on either d-pad
end

local function nav_confirm()
	return btnp(4) or btnp(12) -- O button on either d-pad
end

function Title:update()
	pgui:refresh()
	
	if show_help then
		-- Help screen: allow exiting with any button press
		if btnp(0) or btnp(1) or btnp(2) or btnp(3) or btnp(4) or btnp(5) or btnp(6) or 
		   btnp(8) or btnp(9) or btnp(10) or btnp(11) or btnp(12) or btnp(13) then
			show_help = false
		end
	else
		-- Detect input mode changes
		local current_mouse_x = pgui.stats.mouse.mx
		local current_mouse_y = pgui.stats.mouse.my
		local mouse_moved = (current_mouse_x ~= last_mouse_x) or (current_mouse_y ~= last_mouse_y)
		
		if mouse_moved then
			using_keyboard = false
			last_mouse_x = current_mouse_x
			last_mouse_y = current_mouse_y
		end
		
		-- Handle keyboard navigation
		if nav_up() then
			selected_index = selected_index - 1
			if selected_index < 1 then selected_index = num_buttons end
			using_keyboard = true
		end
		if nav_down() then
			selected_index = selected_index + 1
			if selected_index > num_buttons then selected_index = 1 end
			using_keyboard = true
		end
		
		-- Main menu
		local new_game_label    = "New Game"
		local help_label        = "Help"
		local quit_label        = "Quit"
		local max_width         = max(#new_game_label, #help_label, #quit_label)
		local margin            = 3
		local gap               = 3
		
		-- Calculate button positions BEFORE creating vstack
		local button_height = 6 + margin * 2
		local buttons_stack_pos = vec(SCREEN_WIDTH / 2 - max_width * 5 / 2 - margin * 2,
			SCREEN_HEIGHT / 2 - num_buttons * 7 / 2 - margin * 2)
		
		button_rects = {}
		for i = 1, num_buttons do
			local btn_x = buttons_stack_pos.x
			local btn_y = buttons_stack_pos.y + (i - 1) * (button_height + gap)
			local btn_w = max_width * 5 + margin * 2
			local btn_h = button_height
			button_rects[i] = {x = btn_x, y = btn_y, w = btn_w, h = btn_h}
		end
		
		-- Only override mouse position when using keyboard navigation
		if using_keyboard then
			local selected_btn = button_rects[selected_index]
			if selected_btn then
				pgui.stats.mouse.mx = selected_btn.x + selected_btn.w / 2
				pgui.stats.mouse.my = selected_btn.y + selected_btn.h / 2
			end
		end
		
		local contents          = {
			{"button", {text = new_game_label, margin = margin, stroke = true}},
			{"button", {text = help_label, margin = margin, stroke = true}},
			{"button", {text = quit_label, margin = margin, stroke = true}}
		}
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

		-- Mouse click results from pgui
		new_game_clicked        = stack[1]
		help_clicked            = stack[2]
		quit_clicked            = stack[3]
		
		-- Keyboard confirm on selected button
		if nav_confirm() and using_keyboard then
			if selected_index == 1 then new_game_clicked = true end
			if selected_index == 2 then help_clicked = true end
			if selected_index == 3 then quit_clicked = true end
		end

		if new_game_clicked then self:gotoState("Play") end
		if help_clicked then show_help = true end
		if quit_clicked then exit() end
	end
end

function Title:exitedState()
	new_game_clicked = false
	help_clicked = false
	quit_clicked = false
	show_help = false
	selected_index = 1
	button_rects = {}
	using_keyboard = true
	last_mouse_x = 0
	last_mouse_y = 0
	Log.trace("Exited Title scene")
end

local function draw_instructions()
	cls(1)
	
	local title_y = 8
	local start_y = 20
	local line_height = 8
	local color = 7
	local accent = 15
	local padding = 4
	
	-- Title
	print("CONTROLS", 8, title_y, accent)
	line(8, title_y + 7, 55, title_y + 7, accent)
	
	-- Movement
	print("move: d-pad 2 / wasd", 8, start_y + line_height * 0, color)
	
	-- Aiming
	print("aim: d-pad 1 / arrows", 8, start_y + line_height * 1, color)
	
	-- Shooting
	print("shoot: o / z", 8, start_y + line_height * 2, color)
	
	-- Bombs
	print("bomb: x / x", 8, start_y + line_height * 3, color)
	
	-- Separator line
	line(8, start_y + line_height * 4 + 2, SCREEN_WIDTH - 8, start_y + line_height * 4 + 2, 5)
	
	-- Game Info
	print("GAMEPLAY", 8, start_y + line_height * 5.5, accent)
	line(8, start_y + line_height * 6.3, 60, start_y + line_height * 6.3, accent)
	
	print("* eggs cost 5 hp each", 8, start_y + line_height * 6.5, color)
	print("* 50% dud, 35% hatch, 15% leech", 8, start_y + line_height * 7.5, color)
	print("* defeat enemies for xp", 8, start_y + line_height * 8.5, color)
	print("* level up to boost stats", 8, start_y + line_height * 9.5, color)
	print("* melee attack when hp <= 20", 8, start_y + line_height * 10.5, color)
	
	-- Footer box
	rectfill(5, SCREEN_HEIGHT - 20, SCREEN_WIDTH - 5, SCREEN_HEIGHT - 5, 2)
	rect(5, SCREEN_HEIGHT - 20, SCREEN_WIDTH - 5, SCREEN_HEIGHT - 5, accent)
	print("press any button to continue", 12, SCREEN_HEIGHT - 16, 7)
end

function Title:draw()
	if show_help then
		draw_instructions()
	else
		cls(1)
		camera()
		local game_title_label = "Pizak"
		print(game_title_label, SCREEN_WIDTH / 2 - #game_title_label * 5 / 2, 10, 7)
		pgui:draw()
	end
end

return Title
