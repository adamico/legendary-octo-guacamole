--[[pod_format="raw",created="2025-03-29 18:05:23",modified="2025-09-30 09:46:24",revision=98566]]
-- Debug Panel

--[[pod_type="gfx",content={"Well, aren't you a smart looking tadpole.","Think I'll call you 'Smarty'.","","Okay Smarty, here's how this Debug Panel works.","","1. Add include(\"src/debug.lua\") to your main.lua file","2. Add debug.run() to the end of your _draw() function.","3. Run your cart","4. Press F1 to open the debug panel","","Come find me further down and I'll tell you more."},flavor=3,flipped="false",font=1,head=1001,mono="true",style=2,swapped="false",tab=0,tail=1,text_d=false,text_f=true,text_l=false]]
unpod(
"b64:bHo0AH8KAAAXFAAA9BNweHUAQygdAQAAlgAAAATw-xD-Ef8KIB7w-wgeEA7w-woOBgDzEDAOIA5QHhAe8BIOIA7wLA5wHrAOQA7wAg6gDqAe8EciABBgHQADIgCAgA6wDvAIDqAHAAQgAPEWEB4gDiAOwB4QDgAeEB4QLmA_UA4QDhAeEA4QDmAecC4AHgAOIB4AcQA_YA4gHiAaAPAAAB4QLiAuUD4QHiAuAC4gRAAxHvBCUwARAAIAACUAkSAO4A4AHiAOEBAAM2AOcAoAAAQAM4AOUCwAlTAOAB4wDoAOEB4ANQAOIA4AM2AOUBYAAgQAAgIAJvBBawAQPmkAbsAuAA4wPmcAUWAuYB4QKABYEC4ADkBnACceMGUANDAuABgAARYAIhA_YwAQHv8AUUAOIA6wGwAxMA4wLwAVgC8AEVDMAACyAAISAAljAAXKACAQLocBAxYAMi4QDgIAJPBEhAEwLhAeiAEQcKQAAVsAMHAegJoBYS5gLlAuECIAdAAOUB5gHhCAAQEmAGEwDnAeEC7aAAAYAFAuEA7wPlgA6ggO8Bwe8Ece8AYO8FIONgICBgAgME6rAADJAAACAkAQHvABBQAQDcYBYQMOkA7wf9sAUSAOwA6QogAQIFgCQiAO8A25ABcCJAAhLhB6AAJ6AQDEAAJSAhVgRgI3oA4wRAIAuAAj8INfABMQAgAAKgERcD8AEWA5AAI-ABMABAA3sB4QKgIfIEEAAiMegD8ALEAuPwAR0D0ABAICDz8AAweAAAIXAgKNAQJBADmgDhDiAScwLkEAAooBAAQAEFBsAjIeYC7OAQLAAQC7AAS_AWAwDmAO8Ht-AHtAHvAhHvCElAEPBgA1EEAoBBAEyQFQ8AIO8AXtA-EGBQ4gDkAOsC5gDvADLvABHvAHDvAnQQIAuwAi8APUAQkvACHwAuMAAhwAKgEOMgAE2wEdUNsBM6AuIEsEMXAuUAwAUCAOUD4AFQITLlkEAS0CFRAOAAA9BAEeAwJGAAEcACXwH2sAAHEBABUAHWAFAgKXARMQYwQ0UA6AEAATDlEAAQIABhYABgQANVAuQAwAALgCFSBIAAAIACTwIn0AEh4XBBGAeQAIQQIBewAQPnMEJmAeawIAAgAEeQAzIB5gJAAEHgAAowAC3QMAswQTYDAAABoAZzAeMB7wIPIABiEBCncCAvIAAIUEEbB5BBMAMAAGdwATQBgAEzAeAABGAAQMAALyAwd3AAESACPwHzMCAC0AOTAOYLECAEkBEhD4ADEuUC4MAAElATKAHgD7AjEuYC4BBiUuMN4AAP8CImAOFgIB0QBiLiAO8BwOlAKbEh4gDvBdHvBctAIPBgA1YFAOsB5ADmoDM7AekAoGIPAJyAIxAh6wTgEQgOABQKAe8APzADEe8Az_ABGgfQEQMPoCEZBMAQEVAxJAAAMRsCwBQHAO8C8VAyFwDjQAMlAOoOwAIS5QCwcBQAEB-AARIB4GASEHBx0FAs8BAHMAQIAOYD4iAQREAwAsABJQRgMiHhBkAVMOEB5wDlUHEgdtAAVJAgIhAAC6AQIIAAIWAHMQDnAOMB4gnwIbAAQAAnsAEzDjBAIQAAQcADEAHnASAhEwJAAGLAARUFgHAAwAJfAG8AAPhQAIQT4QDoDyAQODAAv6AgIEAQ_BAAIDYAMDKAEFLAAhYA7nAx8_fwATQw5ADqAcAwF1AgMGAAZ5AQAMAAQAATNgLgASAAB9ABEgCgAIfQACZAABfwAAPgIREFUGAXUAAPABBeYCIRAuAgAA8wYB-AIzQC4QDAMhEA6PByAucBQBIR6QCwYCawAiEC4xBgQiABNgJAIB5gDr8DkO8CAe8AoO8Age8FjbAgIGACJAHuECAEAJIfAT0AIQ0K4FYAsOwB7wF68CYiAOkB7wAc0CERAHARGQCAADNABUEg5ADnA0AECwDvAZ1QIAEwAAMAYRCvkAE5DqABdgvgITQJwFAM4DEkDCAhA__QkRcP4CEGC9CAnSAhKwBAMCTgQjDkB5AQAeATEAPgCtCBug2QITUAgACAQAFUA_CgZEAALrBAwyAAEMABo_2QIRwAYAEVD3AxEQtgAXAC8CABoBAg4AEZAeABWwHAAETgAIwgICMAAPigACOD5QPjgAExB3BAQEABHQBgAAIAIB5gIFPgAPiAADNTAOwBwAA4gAB8sCD4YACEkOgA4whgAGpAoEhAACSAAPhgASFj7wAhdg1gIC6AIBCAAB2gICCAYAJAADCABEHiAOoO4CEj44BhEQgAEAcAATMCYAQiAeAC4qAgJmACDwK_cEcCAO8D8e8CIIABUo7wIIBgCRQB6gLvAqDvC5JwECqQAi8CkQAAK1AgC-ABMApwYTEIkCI2AuWQgzPvC3RQAZEF4BBgcFEWBbCAxQAAwpACEOgAUBGkCJAAQfAApbBAAeAAUrACZAHk8HAZgIAScBIpAubQcBngBb8Bce8OD3AAIGAHBQDqAu8As_ZwMg8BckATEBDlAvABVawQZZ8AoOQB4fACEYDh8AAOkHE6APAQB1AAATBRFQxAMBvgMB9Q0BzAMH8AMBvAkBnAkGQwAB3QYCSQIzgC4wQQIKHAEGjwIOGgAEFAAVMA4AExBdABA_ZQwQME0OEB7wDQtZACg_AGwDBRIACFMAAlMBIwA_UQAALgYRMAYIAJcICVEAEi6zAQSmABeAGQMC9wATEAwAAbcBE1rnCwBJADBALgAOA1EOQC5wHjoBAQcCAKsNAjsABigDCAoJIPBZ5gCbQw7wLB5gDvBv1gEPBgA1UEAe8AkeiQJA8AgesP8BEAYdBhNQ3Q0QcCcOBBIQEBDLCxDgBQAV0CkAE2DkDRFwowYDKQAxQB4QlggAiggB7Q8EDgADSgIRADQCFRBjA1EgDgAucCoAAgkOAGACCgkOA_YIAYYCI-AZlQYBTQABAgAREHQIAAIAAQwABxYAAAYABPYLBK0DBGMFJCAOowsCEgADhg4BLAATEH8AHQBUAAI0DCzwGIUAED4LAQuDACM_YHkABtoIBlUMAgIACPgDBYEAHz5-AAgzDjA_fQAXEMgAGZB9AAISAAl7AC8OMHsAABVQEgAI-gAZQMMOAk4AAkIAQvAbDhAxEABVAAGCCAQpCQIQABEwkQQTAFgDEZD3AwEOACQOYCoAIi5gBAMH6w4BPgASHiwJIPAVXgFEuh7wPaMCAcASgCD_5mD_DPDqWwMg-weLACX-CAYAgDAPIPAEDfDuBAHxCw0HPbA9Bw3w7k4QDRYHBgcNkA0HBgcWDfD2CAARnRQA8BDw9w0mBwYPGx8aDxYvGg8WDxoPGwYHJg3w_A0HFi8VEwDwBR8aLxUWBw3w_Q0WDCcMPxoMJwwWDgCQBgxHDBsMRwwGDQBwAwxHPEcMAwsAEwsYABALDQDwMRsMJww7DCcMGw3w_B0rLFssKx3w9g0KDxsLGitZKxoLCQoN8PQNCxkLGhsJVwkbGgsZCw3w8w0pSxYnBgcGSykNALA5OwYXBgcGBwY7OS0AQBkDCSu8AFAmKwkDGc4AUBkDOVY5CwCw9w0LCRMpVikTCQsYAPACCxkDOwk2CTsDGQsN8Pb9BkA=")

-- Configuration
local config = {
	_X_position    = 1,
	_Y_position    = 11,
	_TOGGLE_key    = "f1",
	_FILL_color    = 1,
	_OUTLINE_color = 7,
	_SHADOW_color  = 1,
	_TEXT_color    = 7,
	_ACCENT1_color = 24,
	_ACCENT2_color = 16,
	_ACCENT3_color = 27,
}

--[[pod_type="gfx",content={"Didn't expect me so soon, eh Smarty? I'm faster than I look.","","Those locals up there are for changing some of the basic stuff","like colors and where the window starts on the screen_"},flavor=3,flipped="false",font=1,head=1001,mono="true",style=2,swapped="false",tab=0,tail=1,text_d=false,text_f=true,text_l=false]]
unpod(
	"b64:bHo0AHAGAADBCgAA9BNweHUAQyhBAQAASQAAAATw-zT-Ef8uIB7w-yweEA7w-y4OBgDwEjAuIA5ADnAOIA7wEg7wOg6QHvADDoAeYC4gDuAesA7wAxoAMAMuUAwAEAcwAEcOEA5wMAAQgEoA0wIOcA4QDmAOMA7QDtA0AEcEDnAONACwAB4gLgAuYD5gHhAOACAuIBAAoT5QHgAOIB5wLhAEALEgHhAuwB4QLmAOMBgAADYAMQA_AEIAkWAOYB4ADnAOMDgAERAcACBQPkgAIRAukAAhHiBaACPwBHEAAgIAEQCYABNwCgAGBAAA8wARAAIAVRAOUA4wBgATAAQAE6AIAACvAAAmAPEAMA4AHjAOIA4QDiAOcA5gFAAxUD4wSgAAFgAxAB6ACAAXMHIAAkIAACoAL-AFlQABAcYARxAOAD6PAAMgASRgHigAAAQAEaAEARKAIgA0DhAudQAAFAACiwAwYA4wQAFiDiA_AA6QHAAdLokAPx7wBocAAQESACAALhoAAgkCRAAOsA5xABcQEgECJgEADgATIBYAkUAOMC6wDmAOIAQAAlwAMyAOMIMAAiQAC4UABQ4BMi4QLqQAQnAeYC4bAHBALhAuIB5QPQBALlAuIIUCA9YBRCAOcC6PAREg3AAgUB5tADFwLlB9AGAwLgAuMB4YADWgHgD_AFNQLmAeEEIAQBAO8AEFALogDvA8DvAiHvB7DgkDDwYANcAwTgAO8Age8AEe8AwIA0AeHvAFlgIw8CIeJQEw0A7gMAMgkB7pAABQAUAgDvAJEgACLgAQHTIDQfA2DoArAILwEg6ADjAOcCkAATQDQhAecA4IAEEgDiAujwEiLmAIA2QOAB4QHnAIACEOMAoAIWAuHABBLiAuAAYAUmAuEB4QdgNkHiAOcD4AaAEQLqIDImAucAMWEHYAAZoBERADAwDLAREQDAATYH4CBOEBBSYAIh4gOQIBCAAiUD4UAAJjAgIbAwAmAAICABcAdQMCAgADXwIWPlAAE1A4ABFAVgADawNJPgA_UJwARBAeED6aAHpALhAOIB5gmgBQPgAOMD5mAhUwXAAAWAEEKAIABAACAgAXAHwDAQIAAWoAAHwAAkgAAQ4AAXwBEBDDAQEWAA4sAQCyADWQDhA2ATIQDkDaACMucCQAMzAOMD4BBi0DApIAEwAEAEEQLhAOAgAULocDESAkAAeOAANCABMQZAARsCgDGxCQABIQ9gEACAMAcgNJHgAucCYDMkAuYAYAATACJJAuGAAARgATAAgAAIwDAngDU2AeIA6QPAAQUFQCAcYDEVB8AwR4AKXwOQ7wVB6wHvBvFAMIBgARMD0BACIDEBMgBhAJ9gIwBQ6Q_AJA0A7wDQ8AE00yAQAZAwYlAB4QIwACQQUDPQYDMQYApQAA8wAA-wAjAC4UABIeIwMA-QECBwMRENEAFWBLBiIAPjgAAigAEXCbBBIAPQRULvAjDhB8AiUOELYCAgIAAOoCAi8FEwB0AQQMAAIEAwYcAwAcAAM0AAUEADEgDlDqAAJdBgTQAQg0ABMwMQETAAQAJPAijQA5HiA_iQAyDkAeJQUCOQACwQIF-QIFwQICFgACMgAEBAAAAgAA2wEhMC7UBQ0-AwATA0AwDjA_TAAIgwABJQADSgMBAgAAGgQTUBgAC4cAKQ4w7AICFgACNAAEBAATANQCAiQAABgBG1ASAROwSAAAAgAEiQAjHgC1AiFgLrABAKwAJC5wFAAEZwAB6wIncB4WACUuAM0DMwAOYD8GEFAhAwFWAhhw5wIBmwYCSgAq8B-RAgFUCfUHIP7-C2D_DPD-Dw5ADvD-Kw4wDvD-LAYAkDAPIPAEDfD-E7cAYA0HPbA9Bw4A8QNOEA0WBwYHDZANBwYHFg3w-xsJABGdFQDwEvD-HA0mBwYPGx8aDxYvGg8WDxoPGwYHJg3w-x0NBxYvFRQAUB8aLxUWLADBHg0WDCcMPxoMJwwWDwCRBgxHDBsMRwwGDgBxAwxHPEcMAwwAEwsaABELDgCQGwwnDDsMJwwbWABwHSssWywrHYkA8A4KDxsLGitZKxoLCQoN8P8ZDQsZCxobCVcJGxoLGTsAsRgNKUsWJwYHBkspDgCxOTsGFwYHBgcGOzkwAEAZAwkryQBRJisJAxncAFEZAzlWOQwAsRwNCwkTKVYpEwkLGgDwAwsZAzsJNgk7AxkLDfD-G-0GQA==")

----Use transparency if Wash's Color Table library is available
-- if ColorTable and ColorTable.apply then
-- 	_FILL_color		= 37
-- 	_OUTLINE_color =  7
-- 	_SHADOW_color	= 38
-- 	_ACCENT1_color	= 45
-- 	_ACCENT2_color	= 46
-- 	_ACCENT3_color	= 47
-- end


-- Create GUI root
debugui = create_gui({
	----------------
	x = config._X_position,
	y = config._Y_position,
	width = 0,
	height = 100,
	pad_x = 3,
	----------------
	show = false,
	----------------
	elements = {},
	----------------
	update = function(self)
		-- Toggle visibility
		if keyp(config._TOGGLE_key) then self.show = not self.show end
		-- Check if on
		if self.show then
			-- Update window width
			local _longest = 0
			for i = 1, #self.elements do
				_longest = max(self.elements[i].width + 6, _longest)
			end
			self.width = _longest
			-- Update handle width
			self.handle.width = debugui.width - 4
			-- Update height
			local _all_height = 15
			for i = 1, #self.elements do
				_all_height += self.elements[i].height + 1
			end
			self.height = _all_height
			-- Group y position
			for i = 1, #self.elements do
				if i == 1 then
					self.elements[i].y = 12
				else
					self.elements[i].y = self.elements[i - 1].y + self.elements[i - 1].height + 1
				end
			end
		else
			-- Reduce size and make unclickable
			self.width = 0
			self.height = 0
		end
	end,
	----------------
	draw = function(self)
		-- Border
		rrectfill(2, 2, self.width - 4, self.height - 4, 1, config._FILL_color) -- Fill
		rrect(1, 1, self.width - 2, self.height - 2, 2, config._OUTLINE_color) -- Outline
		rrect(0, 0, self.width, self.height, 4, config._SHADOW_color)       -- Shadow
	end,
	----------------
})

debugui.config = config

function debugui.run()
	-- Stash font
	debugui.stash_font()
	fetch("/system/fonts/p8.font"):poke(0x4000)
	-- Run stuff
	debugui:update_all()
	debugui:draw_all()
	-- Restore font
	debugui.restore_font()
end

function debugui.create_handle(_x, _y, _w, _h)
	local el = {
		----------------
		x = _x,
		y = _y,
		width = _w,
		height = _h,
		----------------
		clicked = false,
		dragging = false,
		----------------
		cursor = "grab",
		moffset = 0,
		----------------
		draw = function(self)
			-- Bars
			local _factor = self.height / 3
			for i = 0, _factor do
				line(2, 1 + i * _factor, self.width - 3, 1 + i * _factor, debugui.config._OUTLINE_color)
				line(2, 2 + i * _factor, self.width - 3, 2 + i * _factor, debugui.config._SHADOW_color)
			end
			-- Reset status
			self.dragging = false
		end,
		----------------
		click = function(self)
			-- Get offset
			if not self.clicked then
				local mx, my = mouse()
				self.moffset_x = self.parent.x - mx
				self.moffset_y = self.parent.y - my
			end
			self.clicked = true
		end,
		----------------
		release = function(self) self.clicked = false end,
		----------------
		drag = function(self)
			-- Now dragging
			self.dragging = true
			-- Drag parent around
			local mx, my = mouse()
			self.parent.x = mx + self.moffset_x
			self.parent.y = my + self.moffset_y
			-- Protect against edges
			if self.parent.x < 0 then self.parent.x = 0 end
			if self.parent.x > SCREEN_WIDTH - self.parent.width then
				self.parent.x = SCREEN_WIDTH -
					self.parent.width
			end
			if self.parent.y < 0 then self.parent.y = 0 end
			if self.parent.y > SCREEN_HEIGHT - self.parent.height then
				self.parent.y = SCREEN_HEIGHT -
					self.parent.height
			end
		end,
		----------------
	}
	return el
end

----------------
function debugui.create_group(c, bg, folded, func)
	local el = debugui:attach({
		----------------
		x          = 3,
		y          = 0,
		width      = 0,
		height     = 0,
		max_height = 0,
		----------------
		text_col   = c or 7,
		bg_col     = bg or 37,
		folded     = folded,
		func       = func or function(self) end,
		vars       = {},
		----------------
		init       = function(self)
			-- Prep variables
			self:func()
			-- Height
			local _height   = (#self.vars) * 7
			self.height     = _height
			self.max_height = _height
			-- Toggle
			self:tap()
		end,
		----------------
		update     = function(self)
			-- Update variables
			self:func()
			-- Update width
			local _longest = 0
			for i = 1, #self.vars do
				_longest = max(#self.vars[i] * 4, _longest)
			end
			self.width = 1 + _longest
		end,
		----------------
		draw       = function(self)
			-- Fill
			rrectfill(0, 0, self.width, self.height, 1, self.bg_col)
			-- Print Vars
			for i = 0, #self.vars do
				local _txt = self.vars[i + 1] or ""
				local _pad = string.rep(" ", max(0, 15 - #_txt))
				print(_txt.._pad, 1, 1 + (7 * i), self.text_col)
			end
		end,
		----------------
		tap        = function(self)
			-- Toggle fold
			self.folded = not self.folded
			-- Change height
			if self.folded then
				self.height = 7
			else
				self.height = self.max_height
			end
		end,
		----------------
	})

	el:init()

	return el
end

function debugui.create_toggle(c, bg, label, _upd, _drw, _tap)
	local el = debugui:attach({
		----------------
		x        = 3,
		y        = 0,
		width    = 1 + #label * 4,
		height   = 7,
		----------------
		label    = label or "[== empty ==]",
		text_col = c or 7,
		bg_col   = bg or 37,
		----------------
		on       = false,
		upd      = _upd or function() end,
		drw      = _drw or function() end,
		tp       = _tap or function() end,
		----------------
		init     = function(self) end,
		----------------
		update   = function(self)
			-- Extra stuff
			self:upd()
		end,
		----------------
		draw     = function(self)
			-- Fill
			rrectfill(0, 0, self.width, self.height, 1, self.bg_col)
			-- Print Vars
			print("\015"..self.label, 1, 1, self.text_col)
			-- Extra stuff
			self:drw()
		end,
		----------------
		tap      = function(self)
			-- Toggle color
			self.bg_col, self.text_col = self.text_col, self.bg_col
			-- Toggle on
			self.on = not self.on
			-- Extra stuff
			self:tp()
		end,
		----------------
	})

	el:init()

	return el
end

local _FONT = nil
function debugui.stash_font()
	_FONT = userdata("u8", 2048)
	memcpy(_FONT, 0x4000, 2048)
end

function debugui.restore_font()
	memcpy(0x4000, _FONT, 2048)
end

debugui.handle = debugui:attach(debugui.create_handle(2, 3, debugui.width - 4, 7, true, true))


--[[pod_type="gfx",content={"Okay Smarty, here's where the good stuff happens!","","The little colored thingies in the debug panel are called","'Elements' and there are two types. 1. Groups and 2. Toggles.","","Down below is a big list of 'em, and they need to stay there, so","don't go shufflin'em around like a goober-gobber."},flavor=3,flipped="false",font=1,head=1001,mono="true",style=2,swapped="false",tab=0,tail=1,text_d=false,text_f=true,text_l=false]]
unpod(
	"b64:bHo0ACcJAACfEAAA9BNweHUAQyhLAQAAagAAAATw-z7-Ef84IB7w-zYeEA7w-zgOBgAQQBAAoQQe8AMO8AIO8AUGAPESCQ4gDvAQDrAOkB4gHlAO8BMO8D8OEA4wDhAOAA7wAw4QJgAOLwBbgA4wDnAvAPAHEA4QHhAOEA5QDjAeAA4gHhAOAB4APhgAIqAuDgCVEB5wLlAOIA4AEAAgYD4MAKJwLhAeIB4gLmAuMAAAUgAQcCQAIS4QBgA4IC4QaQAxAA5AbwAiYB4OAHAwDgAeMA4gaQADiQAxAB4giQAQgG0ACRQAM2AOIBAAE1AIABUAEAASQBwAQT4APlBsAAQaAAYEABdAhwAwHjAuFQARgIMAQAAOEC4fAAWFAIQ_AA4wPmAeYB4ABBIAA2MADH0AVGAeIA4g_gAACAAVLh4AAhIBKh4gAgERECUAAkcAFSCeACIwLgIBcTAOMA6wDlAqABUAEgASkH0AJg6QXQABwQAZEHsAARgAMi4QLmwAQzAO8EI8AgBxABEwdQERIKAAEVB1ARNgrgBRQC5QLnA9AAQQACFwHg4AMi6ADt4BMFAuMNIBB_IAMjAOQIsAEy7eAACfAhAS6wBATx7wLnwAKlQOxAIPBgA1UTBOAA7QdAGRMA4gHvAGHvAEGwIwQA7A6QIQwOgC8QEBDlAO8Bce8BUeEB6QDvAgJAJRIA7gDmBOATPwBw41ACXwJC8AdhgO8BYOIA4vAADeAgAYA1M_AD4QDuoCFA7_AnEgLlA_AC4Q4gISACQBNh4QLhQDIhAuTgESUAYDRR4gDnBIAwFIABAONAAFmgACvAEA4gIRIKIAERAYAAIIAAACACgAHiQAExACABMACAAACgA1kA4QHgAAGAAMpwIEFAAGHAMzEA6QWAA1UA5gSgIAGgAIlwAXPpUAGT6TAD8OMD6RAARIPhAecI8AAjQDAS4ABAQAE1BIAgAYADAQDnBSAlE_UA5ALocAHD6FACcOkBoBGoCFACsOMIUAAnsBEmDfAgMaADMADoAuAAAGAAKZARMQDAAAfgMTYB4ABFwAESAqAQmFAEAQLmAe3gEgIB7eATJgLhAKAAC0AAMwAzIALgBhAWEuEC4ALmAOAARKAxFgFABTIC4wDlA6A1EQLhAeYG4DABwAERBWABIQEgKr8GQe8DweYA7wa-wCAgYAEFAiAVUe8AgOkMcCEB0KAPIC8BIOsC7wHA5gHqBO8AAe8BUsAAD7BA4sAGERHqAO8B8gABCwLwYBLgAQgAgFIh4QBAZhLhA_EC6w4gImUD74BRZwAAYAGAEBCAABCARgHiAusA6gAAESHk4GAPAAEWBAAHGADrAOMB4gmwQB_AIQCm0AES5XAQPqBBMAjgESEJEDBA8ABL8BBAMDE4AIAAKWAgsiAAEEADDgDqC_BikeIBYAFbAMADlwDsAyAAICAEMADvANAQEiED6QAAO-BUEOMB7AsQEHbQACEQYULhcGAjAABR4AASIAWRAewA6gdAICDQYmcC5MABbQMAAFOQMk8AuHAADgBAM-AADIARegKwAEaQAA-QIE2QIZkIkAQDAuAC4IABywhQBELkAOUAwAAVgAMuAOII4CAzcDApwBED6PAgHhAQGlA0IgHgAuBgEE7QITELsCAi8GAE0AQCAegB5eBBBA6QIyDnAu1wMwQB4gKAEjLnA_ACBQPt8AMDAeQJMAIR4QLAAg8AfcAhCM5QiVKQ7wLB4gHvAZ7gIPBgA7YTAu8AcOgEoJUAYOQA6wmQVxDuAecA7wFFYBQfAVDmAPAxADDQARHIYBEBAsAECQDvAaFgBfsA7QDpAuAAsA-gIAKgkzYC4gMgYwIA5QJAkRHjYEIC5gVgcwLgA_OggR0G4DGcBmAzEQDlBoBAASAAExAiI_EBYAB4YDEMA_BANwABEABAATINABAtwBAgIAEwDmBwBRCBMQAgACPAISQDEIEj4eAgA2AhHQOAAVACIABA4ABFIACh4AAHMJF1AQAAaiAwACBAI2AAacAAICAAIWAADwBRUQFgARYFoHABgAAgIAEmAaBwJoCCMOwIsDIrAuSAAIgQMETgAmAD4YAABSASwwLqkDP7AeEJIACwFuAwaSAAIiAxFQFAAArgERICAAA5IAAZYDFaBIAAVqACMOQNMJCJEGAJwDESD3AgQmAAF-CBUBewARMCMCIwAO9QEBBwYAEABQYC4ALnCkBgG3CWEALgAuMB4vAgGUAwBeAwqMAxEwTgABxQMAjgMhHmCxCSgwDqwDICAOkQIADwIg8E6kCYPwHB7wLx7wEX8DK-84BgASYEwJUQwOoB4gUAVhgA7wHg5Q5QEg8BcwBQPmCQUpABGQ3wAQwCcAOmAOUCUAIUAuNwcxPmAu0wIBbQQAkQECBgQRcAcDBFsGBT0GEg4MAAB1BhJwcQcDAQMRYE4ABA4AKfBH3AEAkgATcAoAArIIAAoAACoCA44BAS0BAu4BBFAGGQA_AAQSAADCAQIsAAsEAAHgCB0AFgAv8EmJAAYAfQsEVQARMEUCA9MDIg4A8AEJOAAFhwBDHiA_YFkCBwQAAdcCCRIAAxYALfBKgQARgCsCAOwMD38AAAEKAAJfAA9-AAIjDgDGAgChACYQDgQAGzCLDAASACTwSugBAC8DEB49DBJg6AEBOwwQMMgCA0sAAIwCBBwGBFsJAwoAA3UMABEFALcHA_gBES7CDRBEewKkEx7wfB7wER7wYasCATIPoCD_-xVg-gzw-xkqACD-NZEAJf82BgCQMA8g8AQN8P8d6QBgDQc9sD0HDgDxA04QDRYHBgcNkA0HBgcWDfD-JQkAEZ0VAPAS8P8mDSYHBg8bHxoPFi8aDxYPGg8bBgcmDfD-Jw0HFi8VFABQHxovFRYsAMEoDRYMJww-GgwnDBYPAJEGDEcMGwxHDAYOAHEDDEc8RwwDDAATCxoAEQsOAJAbDCcMOwwnDBtYAHAdKyxbLCsdiQDwDgoPGwsaK1krGgsJCg3w-yMNCxkLGhsJVwkbGgsZOwCxIg0pSxYnBgcGSykOALE5OwYXBgcGBwY7OTAAQBkDCSvJAFEmKwkDGdwAURkDOVY5DACxJg0LCRMpVikTCQsaAPADCxkDOwk2CTsDGQsN8P8l-QZA")

----------------
-- Elements
----------------
--[[pod_type="gfx",content={"this group elements displays system stuff","like cpu, ram etc."},flavor=4,flipped="false",font=2,head=1048,mono="true",style=2,swapped="true",tab=0,tail=2,text_d=false,text_f=true,text_l=false]]
unpod(
	"b64:bHo0AOoBAAAPAwAA8wlweHUAQyCtHgTwn-8amSAe8JceEA7wmQ4FAMAwLgAOAA4ALhAeUB4GAAIOAHBALgAOIC4AAgBgHhAuQB4QGgACFAAxDgAOLAABCAABIgAhLlAcACEADgwAYA4QDkAOEB4AiQ4QDmAOIA4AAgBRQA4gDiBIABEgJAATUCoAAigAAgYAAAIABDoAEDAcACEuQAgAAiIAEnBiAJIuEA4QLkAOIB4YAAG2ACQeEBAAKB4QXgATLrwAES7aACAuADwAASIAEEAKAAIwACceYLoAWzAOQA4AAgASYLoABagABF4AMzAOABgAAAYAAiYABNIAI2AOYAAGuAACKAEiHlAyAWEeIB4ADmCUAANCAQJaAAJ6ASQOIBYAoR5QHhAuAB4gDhASAGRAHiAOIB5WAALJAQUtAASPARWA8QBBEB7wUiMABEYBEWCeAAACABOACAATAGQBJPBUKQBDHhAeUFQANYAeEHcACCMABUwAFSAQAQboAQZOACYuAJoAIA4w8QAlDgACACJALrUBI-BPygAAogLxCSDOYP6F8AEOQA7wlg4wDvCXDiAO8JA-IFQAQJANPg1xAPAa8JANDg8THgwODRAe8JANDxteCw0ADvCRDX4N8JMNHj8fHg3wlA0OOg4HAIAbDhsOGw3wjw==")
local system_group = debugui:attach(debugui.create_group(7, debugui.config._ACCENT1_color, true,
	function(self)
		self.vars = {
			"[== system ==]",
			"fps: "..tostring(stat(7)),
			"cpu: "..tostring(flr(stat(1) * 1000) / 1000 * 100 .. "%"),
			"ram: "..tostring(flr(stat(0) / 1048576 * 1000) / 1000 .. "MB"),
			"t(): "..
			tostring(string.format("%02d", flr(time() / 3600) % 60)..
				":"..string.format("%02d", flr(time() / 60) % 60)..":"..string.format("%02d", flr(time()) % 60)),
		}
	end))
add(debugui.elements, system_group)
----------------


--[[pod_type="gfx",content={"this group elements shows","some global variables."},flavor=4,flipped="false",font=2,head=1048,mono="true",style=2,swapped="true",tab=0,tail=2,text_d=false,text_f=true,text_l=false]]
unpod(
	"b64:bHo0ALUBAADAAgAA8wlweHUAQyBtHgTwX-8aWSAe8FceEA7wWQ4FAMAwLgAOAA4ALhAeUB4GAAIOAHBALgAOIC4AAgBBHhAuUBYAExAGAHBQDhAOQA4QDACJDhAOYA4gDgACADBADiACACEuABoAOxAOUCIAEnBAAKMuEA4QLkAOIB4QGABUAC5AHhAQACIeEDwAAIIAFA4gAAh6AFswDkAOAAIAEmB6AAFuABEgJgA0cA4AAgA2LiAOQAAA2AASUFoAhB4gHgAOYC4AagABBgA0EA5QiABELgAeYC0BQEAeEB4pAAARASIwHjMAEmA1AAQCAHEOIC4QHvACogATIFAAApgAFwACAAE1AAMCABIQkgADtgBGIA7wBJcBAAIAJB5QPwAmHhBwADAeIA6bAAExAREucAA7UA4AYAALdAAfLnIAAyJADq8ARB4QHhD9ARIubAAEdQEDLQADEgAiAC6AABPgFwEAUwJwIM5g-kXwAU0AYFYOMA7wV8kAQFA-IDAkAEBQDT4NjADwGvBQDQ4PEx4MDg0QHvBQDQ8bXgsNAA7wUQ1_DfBTDR4-Hx4N8FQNDjoOBwCAGw4bDhsN8E8=")
-- add(debug.elements, debug:attach(debug.create_group(7, debug.config._ACCENT2_color, true,
-- 	function(self)
-- 		self.vars={
-- 			"[== globals ==]",
-- 			"x position: "			.. tostring(debug.x),
-- 			"y position: "			.. tostring(debug.y),
-- 			"_TOGGLE_key: "		.. tostring(debug.config._TOGGLE_key),
-- 			"_FILL_color: "		.. tostring(debug.config._FILL_color),
-- 			"_OUTLINE_color: "	.. tostring(debug.config._OUTLINE_color),
-- 			"_SHADOW_color: "		.. tostring(debug.config._SHADOW_color),
-- 			"_TEXT_color: "		.. tostring(debug.config._TEXT_color),
-- 			"_ACCENT1_color: "	.. tostring(debug.config._ACCENT1_color),
-- 			"_ACCENT2_color: "	.. tostring(debug.config._ACCENT2_color),
-- 			"_ACCENT3_color: "	.. tostring(debug.config._ACCENT2_color),
-- 		}
-- 	end)))
----------------


--[[pod_type="gfx",content={"this toggle elements shows an outline sized to","picotron's divverent video modes."},flavor=4,flipped="false",font=2,head=1048,mono="true",style=2,swapped="true",tab=0,tail=2,text_d=false,text_f=true,text_l=false]]
unpod(
	"b64:bHo0AE8CAAARBAAA8wlweHUAQyDBHgTws-8arSAe8KseEA7wrQ4FAOAwLgAOAA4ALhAeQC4QHgIAYAAOIC5ALgYAEAACAFAeEC5QHiQAExAGAGJALgAeYB42AAEmAAIiAAMuALBQLhAeUA4QDkAOEC4AQQ4QDnAKADEADiACABJgCAAAOgABIAARUAgABgIAE2AIABNACAAAQgATMEIAYmAOMA4wDjoAAGQAIwAOagBjLhAOEC5QJgABYABxHlAeEA4gHhIAIh4QagAAoAATDgIAAeIAD2YAAgDCAGwOIA4QHhBmAAEoABMwFAAGAgAF1AADDgARAPQAFAACAE8uIA5A1AAIEYAOAAI_AAxuAABQARBgigAhLgACADRALgDEABIuSAAjUB7iAAB6ASEOAAIAIEAe_AAVECoAFUBAAFdQDhAeYPkBAfEBEQAIACAAHjUBASsAEw4CAAX-ARJADgAjHhAlAgIKACHwKsYAEwDAAAIIABsAGAEKFgAVIAYAAPgBBhwAABIAApABEwAQACHwLKIAB1sAIx4QHQA3QC5AOwAB-QASHh4ACVUAJx4QcQEDKAATLrQAHzCyAAIRYC8ABDoBEyCKAAI6AgQqABwgVQAzDkAOVQATIEYBB34AEB5zAgBrAANWAQEGADIQDmBjAASzAQKfAVMeIA7wJ5wBAKQDcCDOYP6Z8AFgAGCqDjAO8KsWATCkPyC8AFDwpA0_DYsA8BrwpA0ODxMeDA4NEB7wpA0PG14LDQAO8KUNfg3wpw0ePx8eDfCoDQ46DgcAgBsOGw4bDfCj")
-- add(debug.elements, debug:attach(debug.create_toggle(7, 9, "[== vid() ==]",
-- function(self)	--Draw
-- --[[pod_type="gfx",content={"see the example at the bottom","to learn how this all works."},flavor=4,flipped="false",font=2,head=1048,mono="true",style=2,swapped="true",tab=15,tail=2,text_d=false,text_f=true,text_l=false]]unpod("b64:bHo0AM0BAAAmAwAA9QtweHUAQyCQHgTwkf8abfACHvBrHvABDvBtDgYAxkAeAC4ALkAuAA4ADggAAQIASQ4gLkAcABEQLAAABgAQUDsAkDAOIA4gDnAOEB8AQQ5gDiAIAAE-AAEIAJUgDmAOAA4QDmAiABEAAgAyEA4gEgADRwDgLgAeEB5gDhAuAB5QHiAIAANFAGQgHlAuEA4aABgQOwAxDgAOPQA-UA4AhAADA4IAD4QADgRJAEAwHhAukQAYEAgBBQIAECAIAQhJAAAiABAeXwAREJgAFlBRAXIwLhAeQA4gQwEQHqAAIBAeQwAERwEgEB4KAAOYACEeABYAMBAe0DsAEUBcADlADiDHAAB4ABUAqwAREIYAExDJAAJHAAoCACnwAEwAANgAJh4QgQACRgBBLhAOEOYAB0IAXx4QHhAuiQARFC6HADQwDkCHAAVdAAIQAARHACAeUAcBDEUAJR4QagECIwEALQETQKgAAQIARR4gDqBUAQG3AvASAs5g-lnwEA5ADvB5DjAO8HoOIA7wcz8gMA4QDvBzDT4NqwDwGvBzDQ4PEx4MDg0QHvBzDQ8bXgsNAA7wdA1_DfB2DR4-Hx4N8HcNDjoOBwCAGw4bDhsN8GM=")
-- 	camera()
-- 	clip()
-- 	if self.on then
-- 		local _screen_w = get_display():width()
-- 		local _col = 0x0107
-- 		local _flags = "\^o1ff"
-- 		local _fillp = {
-- 			0b10101010,
-- 			0b01010101,
-- 			0b10101010,
-- 			0b01010101,
-- 			0b10101010,
-- 			0b01010101,
-- 			0b10101010,
-- 			0b01010101}
-- 		--Draw vid() modes
-- 		fillp(unpack(_fillp))
-- 		rect(0, 0, 159,  89, _col)	--vid(0) 160x90
-- 		rect(0, 0, 239, 134, _col) --vid(0) 240x135
-- 		rect(0, 0, 479, 269, _col) --vid(0) 480x270
-- 		fillp()
-- 		print(_flags .. "160x90",  129,  81, 7)
-- 		print(_flags .. "240x135", 204, 126, 7)
-- 		print(_flags .. "480x270", 444, 261, 7)
-- 	end
-- end)))
----------------


--[[pod_type="gfx",content={"Hey smarty, Ya' made it!","Down below are some examples to copy.","","And my nephews are there to eplain","things in more detail too. *hop*"},flavor=3,flipped="false",font=1,head=1001,mono="true",style=2,swapped="false",tab=0,tail=1,text_d=false,text_f=true,text_l=false]]
unpod(
	"b64:bHo0AC4FAADHCAAA8wlweHUAQyDHVATwuf8RsyAe8LEeEA7wsw4FABAwCQD-BRYO8AIOEA5wDvAFDrAOIA4wDvA5HAABKPAAGwDxChAeEA4QDmAuAB4ADiAeEA4AHgA_AA4QDqAcABGwFgCTIC4QHmAeED4QNwABIQAABABgUA4wDgAOUADUAB4wDiAOEA6wLjAOoBQAAyYAGmCNAAJgADFgHhAnAFEQLgAOQDsAVdAOEC6gFAAAKAAMOQCiDkAugA4ADiAOAA4AUg4wLtAOrQAEFAAABABjkA4gDvA_NQCREC4wDlAuEA4gVgARUKcAUWAuIC6gEgAAAgBDUC4gHtoAqOAe8BIeIA7weg5eAQEFAPMAMC7wBw6AHvBKHvACDvAaXgCI8AYOkA7wSw4UAABSAZEgDgAuYC4gHiBUARIg7gCBHhAecC4QHhBUATJwHhAsABAe8AARIGYBI1A_IgAQLhwAE5BQAALVABMgcQECEAACAgAAFgBTgA4AHiCLAQJSARkAKgACoQECFAACAgACIQEGMgACBAAKbgACAgADRgAUPjgAAAIAhmAuAA4wPmAeEgAgAD64ACYgLjYAMBAOEMoAD2YAG0UOQA4QFgACEgA3MA6w-gAXgDoAAGABESBbAhhgZgAxLiAuYgABegERAFAAMVAuIHQBABAAEHBsAgPwAQD_ASFgLiQAEi5gAHRAHhAuAC6ApgEyDmAOBACZ8G8O8CAOQB6gEAIPBQApkEAekA7wFQ7wHqkCkwkO8AcecA7wDBsBGYAbABAIDgAVEN4AJVAe1gAAJgIGygADYAJVYD4ALiAMABAQZgIBXAIAVAIr8Ae8AwJrAQR-AQwEAAATAROwXQICZQEBGAAHEAAEOAATELsBAQ8DA6wAAwQAC2UABX0AIwA_GAAiHnBQAgJhABY_DAARUCwAMRAOIAwDD1sAAgD5AAKEABEwJQATAO0CEzCaABMw6QIACgAEDAAxUA4wOQIfELIAAQBPABMgPwAAFgIRMAgAARwAEi48AiRwHjICAAwAAr4AAjgCFABNALnwDx7wAQ7wVA7wG-UBAQUAAOoEsEAO8AcO8BkOYA6AAAFjDvALDvAmHAB28DcOYA7ADhUAMDA_AI0CAMUCMC5QHukBJAAO4QEBpwISPt0CAO0BMSAeoKsAIiAetQAj8BVWAATvABMA-gMZEJoBAtMBE1AgAAIKACIgDr4DBF0FAgoAAiAAL-AWVwAAAMkAC1cANA4wPj8EKjAuUwATkLABAwQAHS6qAAC2BRNgUQATICkAMzAOgCgEAigAD6QABCIuIKIAAisDApkBMzAOAO0DAE8AAN0DMkAuYD8DMS4ALicDEB4zBBFgQwABlwUkDjBCAYPwCB7wbA7wHMQBAHwHgCD_kGD_DPCUzAEQsKMGFLEFAIAwDyDwBA3wmDwC8QsNBz2wPQcN8JhOEA0WBwYHDZANBwYHFg3woAgAEZ0UAPAQ8KENJgcGDxsfGg8WLxoPFg8aDxsGByYN8KINBxYvFRMA8AUfGi8VFgcN8KMNFgwnDD8aDCcMFg4AkAYMRwwbDEcMBg0AcAMMRzxHDAMLABMLGAAQCw0A8DEbDCcMOwwnDBsN8KIdKyxbLCsd8KANCg8bCxorWSsaCwkKDfCeDQsZCxobCVcJGxoLGQsN8J0NKUsWJwYHBkspDQCwOTsGFwYHBgcGOzktAEAZAwkrvABQJisJAxnOAFAZAzlWOQsAsKENCwkTKVYpEwkLGADwAgsZAzsJNgk7AxkLDfCg-QZA")
--------------------------------
-- Example Group
--------------------------------
--[[pod_type="gfx",content={"here's the arguments for create_group(text_color, fill_color, start_unfolded)"},flavor=4,flipped="false",font=2,head=1048,mono="true",style=2,swapped="true",tab=0,tail=2,text_d=false,text_f=true,text_l=false]]
unpod(
	"b64:bHo0ACsCAAAGBAAA9BNweHUAQyhBAQAAGAAAAATw-zT-Gv8uIB7w-yweEA7w-y4OBgBgMA4ADgAuAgBxEA4gHkAuABAAEEAQACQeABwAYB4QLhAeQBIAVC5QHgAuAgAmUB4mAFMQDhAuAD4AIFAeFgBRMB4ALoAUADUgDnASABWQQAAQQCwAAVoAtAAOIB4QLgAeIA5gkgAjDiAGAFEgDnAOEAwAEWAGAAUcABIuCABSEA4QDmASAEMOAA5ACgAOGgAGAgAzMA4QIAAXUC4AAAIAE4AcAB9gGAACAgwAADYAAgoABCAABgYAMCAOUMAAADABYB4QHlAuUBQBIB5QEAADJgAB8gABRgAxEC5ACgAwAB5Q-gAACAEiDhAMAAAWAAPiAEAwDhAeBAEJqgBOHpAeIKgAIh6QhAEQHi4ACGwABCAAERAKABtQYgERgBIACmABCAIAESCuABUwWgEPZAEBHQA0AAJIAQ9kAQEAEgAPZgEDERDqAR8QaAEXAyQBAAYAMkAeYDoAAlYCApICJR4AIgAIXAEaUBgAAo4CABIAIB4gpAJFDiAOEBwAIBAeogIESAEyYA4gLgAMGAABkAEnAA42AAEMAAHWAgNcAxRgcgMBhAPxDiDOYP7-GvABDkAO8P8rDjAO8P8sDiAO8P8lPyAwKgBAJQ0_DewAAAoAcA4PEx4MDg07AHAlDQ8bXgsNGADxBSYNfg3w-ygNHj8fHg3w-ykNDjoOCACQGw4bDhsN8P8k")
-- add(debug.elements, debug:attach(create_group(7, debug.config._ACCENT1_color, true,
-- function(self)
----[[pod_type="gfx",content={"to track a variable in a debug group add a","new line to self.vars and put the variable","inside the 'tostring(here!)' part."},flavor=4,flipped="false",font=2,head=1048,mono="true",style=2,swapped="true",tab=15,tail=2,text_d=false,text_f=true,text_l=false]]unpod("b64:bHo0AM0CAADpBQAA9QtweHUAQyDEJATwxf8aofACHvCfHvABDvChDgYA9QkwLhAeQC4ALgAuEB4ADgAOQC5ADgAOAC4CAMEOIC5ALgAeUC5AHhAQAGQADhAeUB4wABEAHgBQEB5QLlBPAHFADhAOAA5QBgACAgAQIFUAAwQABAIAGRAgADlwDhAkAAAyAAICABdgDAACAgACIgAGDAAKdQAAogBEDiAeUMQAQB4gDhCeAGYOIB5gDhDeAEQeEB4QYQADCgADygAEWwAPzgAOHy7MAB0EEgAIAgA5YA4AHgAEdQADrgACbAEGHQAGqgADBgAULrQAA5MAAsYBBMgAMx4gHmMAACgABF8AA-cBIx4QOQAQICEBMi5ALtUBAe8BAzMAARkCAdsBCR8BBSAAAwIAIg4gLQEVMPEAM0AOMKwABA8BESACAAjvAA79AAJNAQT6AAgeAAxjAQRtACgeEG0ABeMBAvEBElCmACQeELgAAhwABGUAANMCDyUCAAbIABwuxgAAkgABxgAWLowABLgAEwDmAANdAAEQAAYoAA-AAAUCvwECJwAhLlBXAwJjAzYwDiAzAAKoAAN6ASUwHmEAJi5QJAADRAAAAgAI5QERLgQCCAUBADUAUi4QHhAeLQAAIAADngACPgIB4gAiUC4OACbwGgUDGwAOAQAQARkwGgAE5gAAQgACCAACHAATMDwBBg4BJ-AbWAAmLhC-AUYuAB6gFgAmHiBSABEutANiHiAOMA6AuAAJRgAAKgAKngAZsBgABB4AAAIACJ4AM4AOgAoABpgAEjAqAQKLAQRlATIukA6AABcQbwEbEA4ANyAOkE4ARSAO8BeMAQF6BfACAs5g-o3wEA5ADvCtDjAO8K4kADCnPyBAAVDwpw0_DT0A8Brwpw0ODxMeDA4NEB7wpw0PG14LDQAO8KgNfg3wqg0ePx8eDfCrDQ46DgcAgBsOGw4bDfCX")
-- 	self.vars={
-- 		"[== example ==]",
-- 		"variable: "	.. tostring("variable"),
-- 		"greeting: "	.. tostring("hello!"),
-- 		"rainbow: "		.. tostring("\f8p".."\f9r".."\fao".."\fbm".."\fci".."\fds".."\fee"),
-- }end)))
--[[pod_type="gfx",content={"\009\009\009^\009\009\009\009\009\009\009\009\009\009^","\009 label here\009\009\009\009\009\009\009variable there"},flavor=4,flipped="false",font=2,head=1048,mono="true",style=2,swapped="true",tab=15,tail=2,text_d=false,text_f=true,text_l=false]]
unpod(
	"b64:bHo0AC0BAAD8AQAA9gtweHUAQyDYHgTw2f8atfACHvCzHvABDvC1DgYAcRkO8GcO8BMMAGAYDgAO8GUFACwSDigACAYAUAQOIC4AAgBRDmAOAA4KADUu8D0LAAECAGUOIC5ALgAUABRQOQAjDgACADMgDmAIAAAGAEXwPw4AAgAzEA4QCgAAHwA3cA4QKQAWcIIAYh4QHhAOYAgAMh7wPmwAQB4gDhATAGMOIB5gDhAdAB9gfgAOAqsAD3wAEwfXABJACgABEAAm8D47AAMTAAL6ABcQEgAVUEcBAY0B8BICzmD_ofAQDkAO8MEOMA7wwg4gDvC7PyAwDhAO8LsNPg15APAa8LsNDg8THgwODRAe8LsNDxteCw0ADvC8DX4N8L4NHj8fHg3wvw0OOg4HAIAbDhsOGw3wqw==")
--------------------------------


--------------------------------
-- Example Toggle
--------------------------------
--[[pod_type="gfx",content={"these (7, 9, \"label\") arguments are","text_color, fill_color, and label"},flavor=4,flipped="false",font=2,head=1048,mono="true",style=2,swapped="true",tab=0,tail=2,text_d=false,text_f=true,text_l=false]]
unpod(
	"b64:bHo0APABAABsAwAA8wlweHUAQyCZHgTwi-8ahSAe8IMeEA7whQ4FAPAEMC4ADgAOAC4QHgAuUA4QLoAugBAAQA4gLgACAJEOIA4ADhAOUC4iAAEqAJAALgAeEC4QHkAKAAA0AEIOQA4QNABwDiAOYA5ADkIAA0YAAQYABBwAAAYAE0AQAAMcAAViAFMQDmAOAAIAEnBUAAFoADAAHlBSACAuwJIAgB4QHhAOgA5ACgAjDiAuAAAMAAFCABEuGAAnHmCSAABuABFgDgAAVAA3kA4gfgAXgIwACAIAApAAPDAOQJAAArAAYx4QLlAOMOIAJaAuFAFALlAOUAwABE4BA94AAZoAFh4aABdQeQEDPQAgUB4vAFEwHgAugBQAOCAOcBIAEB4-AASPASPwAIwAAqYAEVAIABMABgAAlAARMBwAHWAYABUAAgAVQBYAACAABFEAEB6hAQlPAE4ekB4gTQAiHpC2AAJJAAOTAQ_WAAwAEgAPmAADFhA0AQ_aAAYjLgDfASIQHhECAtsBFGAUAQ0YABIAAgAnLkCdARPQdwEA-wLwAiDOYP5x8AEOQA7wgg4wDvCDbQAwfD8gowBQ8HwNPg2GAPAa8HwNDg8THgwODRAe8HwNDxteCw0ADvB9DX4N8H8NHj8fHg3wgA0OOg4HAIAbDhsOGw3wew==")
-- add(debug.elements, debug:attach(debug.create_toggle(7, 2, "[== example ==]",
-- function(self)	--Update
-- --[[pod_type="gfx",content={"put your update stuff here"},flavor=4,flipped="false",font=2,head=1048,mono="true",style=2,swapped="true",tab=15,tail=2,text_d=false,text_f=true,text_l=false]]unpod("b64:bHo0ADUBAADKAQAA9QtweHUAQyCEGATwhf8aYfACHvBfHvABDvBhDgYA5jAuAA4ADgAuQA4ADhAeDADTAC4AHhAuAC4ALlAeACQABRoAABYAAT0AIQ4AAgBZEA5QDgACAAEpAAcCAJEQDhAOYA4wDhAOADMgDmAIAAAGABZwiAAyEA5QbAAAAgAiHlBuAAEGAHIQDhAeUC4QQQAQHgwAAAYAMhAeYIgAESA9AD1wDgCEAAJkAAKCAD_ADhCCAAgxDjAegAAhHiAIAWNQHgAOIC47AHUuQB4gDiAeOQADlgAVUEkBAVsB8AkCzmD_TfAQDkAO8G0OMA7wbg4gDvBnPyD4AFDwZw0_DW8A8BrwZw0ODxMeDA4NEB7wZw0PG14LDQAO8GgNfg3wag0ePx8eDfBrDQ46DgcAgBsOGw4bDfBX")

-- 	if self.on then
-- --[[pod_type="gfx",content={"stuff in here only runs when the button is toggled on."},flavor=4,flipped="false",font=2,head=1048,mono="true",style=2,swapped="true",tab=30,tail=2,text_d=false,text_f=true,text_l=false]]unpod("b64:bHo0ALoBAADzAgAA9RJweHUAQygDAQAAGAAAAATw-xT-GtHwER7wzx7wEA7w0Q4GAPMCQB4ALgAOAA4ALgAuQC4AHlAMANIALlAeAB4QDiAOAA5AIgBAHiAeQAgAAi4AIx5QOAADHgBQLgAuEB4WAGAQHkAuEB4CALAADiAuAB5gHgAeoGsAUDAOMA4QKwBBDiAOcAoAE0AOAAAGABFgBgAEEAACGgAEAgAKHAA5UA4QFgAApQATEAwAABwAE3AOABMgAgAGTgARkIcAIi4QIQBiHhAeYA4Q4AABsAAB-AACOwBDLkAeEAwAMwAuQPIAEhBhAAD8AC4eEHkAKC5QeQAsHhB5AAAfAA8AAREVQDcAAh4AA2EBASgAH1D8AAoVMCAABj4ADgABEB6eAAAbADRgLgAdAATMASQeEAwCAF0AER4WAAXqARYAgQARLuQBAH0AFB5CARBgDAAjLgACAAJKADUQDmBrAgF9AvAJEc5g-r3wHw5ADvDsDjAO8O0OIA7w5j8gGgJQ8OYNPg2vAPAa8OYNDg8THgwODRAe8OYNDxteCw0ADvDnDX4N8OkNHj8fHg3w6g0OOg4HAIAbDhsOGw3wxw==")

-- 	end
-- end,
-- function(self)	--Draw
-- --[[pod_type="gfx",content={"uncomment these if you want to","draw outside of the debug window."},flavor=4,flipped="false",font=2,head=1048,mono="true",style=2,swapped="true",tab=15,tail=2,text_d=false,text_f=true,text_l=false]]unpod("b64:bHo0ANMBAACaAwAA9QtweHUAQyCgHgTwof8affACHvB7HvABDvB9DgYAwTAOAA4AHiAeEB4ALgIAYB4QLkAuABYAEC4UAKBALgAuQA4ADhAeFAAACgAEJABFEB7wAkIAAQIAEiAeABIuCgBTEA5gDhAYADEgDnAQABUAAgABSgADAgAEKgAPUAACBAIAJB4QKgABgACJAB5gDhAeUC5QAB8uTgAWJw4gKgACPgAAogAzgA4AAgADBAENUAAyQB4ADgEBkAAdAHYABkIBIGAuWAELSAA3HvADfAEhHhAuAUYADlAecgEAQAASUHoBARQAFUAmADQQHkBiACEeIDIAGpDjAAcLAQFxADIQDjCVAAN7ARlwDgAGEQETYC4AGQACAAZdAACCAApZABMuLwAhHlAGAAKWAQIMAD8QHhBVABIEAgAlLkBXAACuAAY9AA_wAAcAnwELWwASLlkAAagAA1cAANYCIg4QPgEARgEETwAAWgEWLt4CFABUARAuogEEnQEBKwPwCQLOYP5p8BAOQA7wiQ4wDvCKDiAO8IM-IKgAUPCDDT4NkwDwGvCDDQ4PEx4MDg0QHvCDDQ8bXgsNAA7whA1_DfCGDR4-Hx4N8IcNDjoOBwCAGw4bDhsN8HM=")
-- 	camera()
-- 	clip()

-- --[[pod_type="gfx",content={"put your draw stuff here"},flavor=4,flipped="false",font=2,head=1048,mono="true",style=2,swapped="true",tab=15,tail=2,text_d=false,text_f=true,text_l=false]]unpod("b64:bHo0ACUBAAC4AQAA9QtweHUAQyB8GATwff8aWfACHvBXHvABDvBZDgYA4zAuAA4ADgAuQA4ADhAeDABBHhAuABgAM1AeACAAAiIAAAgAMQAuUDkAIQ4AAgBZEA5QDgACAAEpAAkQADEwDhAKADMgDmAIAAAGABZwgAAyEA5QaAAAAgARHlEAIR4QEgAyQC4QPQBQHhAeUC4GADIQHmCAABEgOQA-cA4AfAAFTy5gDhB6AAgxDjAeeAAyHiAeagAABgAEAgFFIA4gHjcAAhoAJS5QNwEBSQHwCQLOYP5F8BAOQA7wZQ4wDvBmDiAO8F8-IO4AUPBfDT4NbQDwGvBfDQ4PEx4MDg0QHvBfDQ8bXgsNAA7wYA1_DfBiDR4-Hx4N8GMNDjoOBwCAGw4bDhsN8E8=")

-- 	if self.on then
-- --[[pod_type="gfx",content={"stuff in here only runs when the button is toggled on."},flavor=4,flipped="false",font=2,head=1048,mono="true",style=2,swapped="true",tab=30,tail=2,text_d=false,text_f=true,text_l=false]]unpod("b64:bHo0ALoBAADzAgAA9RJweHUAQygDAQAAGAAAAATw-xT-GtHwER7wzx7wEA7w0Q4GAPMCQB4ALgAOAA4ALgAuQC4AHlAMANIALlAeAB4QDiAOAA5AIgBAHiAeQAgAAi4AIx5QOAADHgBQLgAuEB4WAGAQHkAuEB4CALAADiAuAB5gHgAeoGsAUDAOMA4QKwBBDiAOcAoAE0AOAAAGABFgBgAEEAACGgAEAgAKHAA5UA4QFgAApQATEAwAABwAE3AOABMgAgAGTgARkIcAIi4QIQBiHhAeYA4Q4AABsAAB-AACOwBDLkAeEAwAMwAuQPIAEhBhAAD8AC4eEHkAKC5QeQAsHhB5AAAfAA8AAREVQDcAAh4AA2EBASgAH1D8AAoVMCAABj4ADgABEB6eAAAbADRgLgAdAATMASQeEAwCAF0AER4WAAXqARYAgQARLuQBAH0AFB5CARBgDAAjLgACAAJKADUQDmBrAgF9AvAJEc5g-r3wHw5ADvDsDjAO8O0OIA7w5j8gGgJQ8OYNPg2vAPAa8OYNDg8THgwODRAe8OYNDxteCw0ADvDnDX4N8OkNHj8fHg3w6g0OOg4HAIAbDhsOGw3wxw==")
-- 		circfill(240, 136, 18,  1)
-- 		for i = 0, 6 do circfill(240, 136, 17-i*2,  8+i) end
-- 		circfill(240, 136,  3,  1)
-- 		rrectfill(216, 137, 49, 19, 2, 1)
-- 		rrectfill(217, 138, 47, 17, 2, 7)
-- 		print("promise", 227, 144, 1)
-- 	end
-- end,
-- function(self)	--Tap
-- --[[pod_type="gfx",content={"anything here gets run when","this toggle is clicked."},flavor=4,flipped="false",font=2,head=1048,mono="true",style=2,swapped="true",tab=15,tail=2,text_d=false,text_f=true,text_l=false]]unpod("b64:bHo0ALcBAADqAgAA9QtweHUAQyCIHgTwif8aZfACHvBjHvABDvBlDgYAsjAuAB4QDgAOAC4ABgBCHiAeQAoAUC4ALlAeBgAyEB5AHgAgHlAGAAMoABFgPwAlDgACADUQDhAGADEADmAGABMgDABTIA4wDhAUAAICAAFlAAUkABNQjAAAEQBVLhAOEC5HAACgAMIeEB5QDiAeIA4QLkCuAARBAAO_ABhQjAAbIIoABGwAFyCYADMwDjAWAAMiACUuACQACU0AFACKAAOcABhADAARLh4AARYBJxAeRwABBgAZUGUBARcAAEkBERDPAEAADiAuDAARUAoAIxAeNwAwHvALMAAVQMAAM3AOEJgAAAIAAA4ABEwBFSCwACPwCjQAAI0AKC5QMgAgHmAzAQQyAAB6AAgwAAFkACQwDjIABAIAAGgAAB4BD2gABgUBAjEQHhAnAgELASMeYC0CA8wAVS4QDvAHBAEBewLwCQLOYP5R8BAOQA7wcQ4wDvByDiAO8Gs-IGgAUfBrDT4NZwDwGWsNDg8THgwODRAe8GsNDxteCw0ADvBsDX4N8G4NHj8fHg3wbw0OOg4HAIAbDhsOGw3wWw==")

-- end)))
--------------------------------
