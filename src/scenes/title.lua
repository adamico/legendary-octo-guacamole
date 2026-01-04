local pgui             = require("lib/pgui")
local SceneManager     = require("src/scenes/manager")
local MenuNav          = require("src/ui/menu_nav")
local Title            = SceneManager:addState("Title")

local new_game_clicked = false
local quit_clicked     = false
local help_clicked     = false
local show_help        = false
local fprint           = function(...)
	require("src/utils/text_utils").fprint(simple_font, ...)
end

local characters_y = SCREEN_HEIGHT / 2 - 80

local chicken = {
	x = SCREEN_WIDTH / 2 - 80,
	y = characters_y,
	sprite_id = 200,
	animation = {
		frames = {1, 2},
		speed = 0.2
	}
}

local player = {
	x = SCREEN_WIDTH / 2 + 40,
	y = characters_y,
	sprite_id = 203,
	animation = {
		frames = {2, 3},
		speed = 0.2
	}
}

-- Menu navigation
local nav              = MenuNav.new(3)

function Title:enteredState()
	Log.trace("Entered Title scene")
	pal()
	palt()
	camera()
	poke(0x550b, 0)
	show_help = false
	nav:reset()
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
		-- Update navigation and check for confirm
		local confirmed         = nav:update(pgui)

		-- Main menu
		local new_game_label    = "New Game"
		local help_label        = "Help"
		local quit_label        = "Quit"
		local max_width         = max(#new_game_label, #help_label, #quit_label)
		local margin            = 3
		local gap               = 3

		-- Calculate button positions BEFORE creating vstack
		local buttons_stack_pos = vec(SCREEN_WIDTH / 2 - max_width * 5 / 2 - margin * 2,
			SCREEN_HEIGHT / 2 - nav.num_buttons * 7 / 2 - margin * 2)

		nav:calculate_button_rects(buttons_stack_pos, nav.num_buttons, max_width, margin, gap)
		nav:apply_hover(pgui)

		local contents = {
			{"button", {text = new_game_label, margin = margin, stroke = true}},
			{"button", {text = help_label, margin = margin, stroke = true}},
			{"button", {text = quit_label, margin = margin, stroke = true}}
		}
		local stack = pgui:component("vstack", {
			pos      = buttons_stack_pos,
			height   = 0,
			box      = false,
			stroke   = false,
			margin   = 0,
			gap      = gap,
			contents = contents,
			color    = {8, 23, 7, 21}
		})

		chicken.sprite_id = 200 + chicken.animation.frames[flr(t() / chicken.animation.speed) % #chicken.animation.frames + 1]
		player.sprite_id  = 203 + player.animation.frames[flr(t() / player.animation.speed) % #player.animation.frames + 1]

		-- Check button activations (mouse click or keyboard confirm)
		new_game_clicked = nav:is_activated(1, stack[1], confirmed)
		help_clicked     = nav:is_activated(2, stack[2], confirmed)
		quit_clicked     = nav:is_activated(3, stack[3], confirmed)

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
	nav:reset()
	Log.trace("Exited Title scene")
end

local function draw_instructions()
	cls(1)

	local title_y = 8
	local start_y = 20
	local line_height = 10
	local color = 7
	local accent = 8

	-- Title
	fprint("CONTROLS", 8, title_y, accent)
	-- Movement
	fprint("Move: d-pad 2 / WASD keys", 8, start_y + line_height * 0, color)

	-- Aiming
	fprint("Aim: d-pad 1 / Arrow keys", 8, start_y + line_height * 1, color)

	-- Shooting
	fprint("Shoot: O button | Z key", 8, start_y + line_height * 2, color)

	-- Bombs
	fprint("Bomb: X button | X key", 8, start_y + line_height * 3, color)

	-- Separator line
	local line_y = start_y + line_height * 5 - 4
	line(8, line_y, SCREEN_WIDTH - 8, line_y, 5)

	-- Game Info
	fprint("GAMEPLAY", 8, start_y + line_height * 5.5, accent)

	fprint("* shooting eggs cost 5 hp each (50% dud, 35% hatch, 15% leech)", 8, start_y + line_height * 6.5, color)
	fprint("* defeat enemies for xp", 8, start_y + line_height * 7.5, color)
	fprint("* level up to boost stats", 8, start_y + line_height * 8.5, color)
	fprint("* melee attack when less then 1 heart left", 8, start_y + line_height * 9.5, color)

	-- Footer box
	local footer_x1 = 5
	local footer_x2 = SCREEN_WIDTH - 5
	local footer_y1 = SCREEN_HEIGHT - 85
	local footer_y2 = footer_y1 + 15
	rectfill(footer_x1, footer_y1, footer_x2, footer_y2, 2)
	rect(footer_x1, footer_y1, footer_x2, footer_y2, accent)
	if t() * 60 % 30 < 15 then
		fprint("Press any button to continue", 12, footer_y1 + 4, 7)
	end
end

function Title:draw()
	if show_help then
		draw_instructions()
	else
		cls(3)
		camera()
		local game_title_label = "Pizak"
		local font_scale = 2
		local x = SCREEN_WIDTH / 2 - (#game_title_label * 5 * font_scale) / 2
		fprint(game_title_label, x + 1, 11, 21, font_scale)
		fprint(game_title_label, x, 10, 8, font_scale)
		spr(chicken.sprite_id, chicken.x, chicken.y)
		spr(player.sprite_id, player.x, player.y)
		pgui:draw()
	end
end

return Title
