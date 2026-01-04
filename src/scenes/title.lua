local pgui             = require("lib/pgui")
local SceneManager     = require("src/scenes/manager")
local MenuNav          = require("src/ui/menu_nav")
local Title            = SceneManager:addState("Title")

local new_game_clicked = false
local quit_clicked     = false
local help_clicked     = false
local credit_clicked   = false
local show_credits     = false
local show_help        = false
local fprint           = function(...)
	require("src/utils/text_utils").fprint(simple_font, ...)
end

local characters_y = SCREEN_HEIGHT / 2 - 74

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
local nav              = MenuNav.new(4)

function Title:enteredState()
	Log.trace("Entered Title scene")
	pal()
	palt()
	camera()
	poke(0x550b, 0)
	show_help = false
	nav:reset()
   fetch(CARTPATH.."sfx/title.sfx"):poke(0x80000) -- load 256k into 0x80000..0xbffff
   music(0, nil, nil, 0x80000) -- play music using 0x80000 as the audio base address
end

function Title:update()
	pgui:refresh()

	if show_help or show_credits then
		if btnp(0) or btnp(1) or btnp(2) or btnp(3) or btnp(4) or btnp(5) or btnp(6) or
		   btnp(8) or btnp(9) or btnp(10) or btnp(11) or btnp(12) or btnp(13) then
			show_help = false
         show_credits = false
		end
	else
		-- Update navigation and check for confirm
		local confirmed         = nav:update(pgui)

		-- Main menu
		local play_button_label = "   Play   "
		local title_help_label  = "   Help   "
      local credits_label     = "  Credits  "
		local exit_button_label = "   Exit   "
		local max_width         = #credits_label
		local margin            = 3
		local gap               = 3

		-- Calculate button positions BEFORE creating vstack
      local buttons_stack_x = SCREEN_WIDTH / 2 - max_width * 5 / 2 - margin * 2
      local buttons_stack_y = SCREEN_HEIGHT / 2 - nav.num_buttons * 7 / 2 - margin * 2 - 4
		local buttons_stack_pos = vec(buttons_stack_x, buttons_stack_y)

		nav:calculate_button_rects(buttons_stack_pos, nav.num_buttons, max_width, margin, gap)
		nav:apply_hover(pgui)
		nav:play_hover_sfx(pgui)

		-- Pad labels to same width for uniform buttons
		local contents = {
			{"button", {text = MenuNav.pad_label(play_button_label, max_width), margin = margin, stroke = true}},
			{"button", {text = MenuNav.pad_label(title_help_label, max_width), margin = margin, stroke = true}},
			{"button", {text = MenuNav.pad_label(credits_label, max_width), margin = margin, stroke = true}},
			{"button", {text = MenuNav.pad_label(exit_button_label, max_width), margin = margin, stroke = true}}
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
      credit_clicked   = nav:is_activated(3, stack[3], confirmed)
		quit_clicked     = nav:is_activated(4, stack[4], confirmed)

		if new_game_clicked then
         sfx(1)
         self:gotoState("Play")
      end
		if help_clicked then show_help = true end
      if credit_clicked then show_credits = true end
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

local function draw_footer()
	-- Footer box
   local accent = 8
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

   draw_footer()
end


local function draw_credits()
   cls(1)
   fprint("CREDITS", 8, 8, 8)
   fprint("Game Design & Programming: kc00l + AI agents (Anthropic Claude + Google Gemini)", 8, 30, 7)
   fprint("Art: spritesheets from ToyBox Jam 2025 assets", 8, 42, 7)
   fprint("Music: Picotunes vol 1 by @grubermusic, adapted to Picotron by @kc00l", 8, 54, 7)

   fprint("Made with Picotron for ToyBox Jam 2025", 8, 80, 7)

   draw_footer()
end

function Title:draw()
	if show_help then
		draw_instructions()
   elseif show_credits then
      draw_credits()
	else
		cls(0)
      local band_height = 80
      local band_x1 = 0
      local band_y1 = SCREEN_HEIGHT / 2 - band_height / 2
      local band_x2 = SCREEN_WIDTH
      local band_y2 = SCREEN_HEIGHT / 2 + band_height / 2
      local band_fill = 13
		rectfill(band_x1, band_y1, band_x2, band_y2, band_fill)
		local game_title_label = "Pizak"
		local font_scale = 2
		local x = SCREEN_WIDTH / 2 - (#game_title_label * 5 * font_scale) / 2
		fprint(game_title_label, x + 1, 11, 21, font_scale)
		fprint(game_title_label, x, 10, 8, font_scale)
		spr(chicken.sprite_id, chicken.x, chicken.y)
		spr(player.sprite_id, player.x, player.y)
		pgui:draw()
		nav:draw_arrow(pgui)
	end
end

return Title
