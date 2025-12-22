--- A simple logging library
--- @script log.lua
--- @author Andrea D'Amico AKA kc00l
--- @license MIT
local log = {}

--- @table Levels: level names to numbers
local Levels = {
	trace = 1,
	debug = 2,
	info = 3,
	warn = 4,
	error = 5,
	fatal = 6,
}

--- @table log.levels: level names and colors for terminal logging
log.levels = {
	{ name = "trace", color = "\27[34m", },
	{ name = "debug", color = "\27[36m", },
	{ name = "info",  color = "\27[32m", },
	{ name = "warn",  color = "\27[33m", },
	{ name = "error", color = "\27[31m", },
	{ name = "fatal", color = "\27[35m", },
}

log.current_level = Levels.info
log.outfile = nil

--- Formats a timestamp into MM:SS.mmm format
--- @param timestamp number
--- @return string
local function format_timestamp(timestamp)
	local minutes = math.floor(timestamp / 60)
	local seconds = math.floor(timestamp % 60)
	local milliseconds = math.floor((timestamp % 1) * 1000)
	return string.format("%02d:%02d.%03d", minutes, seconds, milliseconds)
end

--- Formats a log entry
--- @param level_index integer
--- @param level_name string
--- @param timestamp number
--- @param message string
--- @return string
local function format_log_entry(level_index, level_name, timestamp, message)
	return log.levels[level_index].color .. " " .. level_name .. " " .. format_timestamp(timestamp) .. "\t" .. message
end

--- Prints a message to the console or to an outfile
--- @param level_index integer
--- @param level_name string
--- @param message any
--- @param ... any
local function log_message(level_index, level_name, message, ...)
	if level_index < log.current_level then return end

	local formatted_message = string.format(message, ...)
	local presentation = format_log_entry(level_index, level_name, time(), formatted_message)
	printh(presentation)

	if log.outfile then
		store(log.outfile, presentation)
	end
end

for i, level in ipairs(log.levels) do
	log[level.name] = function(message, ...) log_message(i, level.name:upper(), message, ...) end
end

function log.init(level_name)
	log.set_level(Levels[level_name] or log.current_level)
end

function log.set_level(level)
	log.current_level = level
end

function log.set_outfile(filename)
	log.outfile = filename
end

function log.get_outfile()
	return log.outfile
end

return log
