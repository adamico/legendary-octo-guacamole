--[[pod_format="raw",created="2024-09-08 09:50:21",modified="2025-03-07 13:16:28",revision=8]]
--[[
	require.lua - Lua 5.4-compatible "require"
	(c) 2025 Andrew Vasilyev. All rights reserved.

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program. If not, see <https://www.gnu.org/licenses/>.
]]

--[[
globals.lua - global utility functions
(c) 2025 Andrew Vasilyev. All rights reserved.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.
]]

local wm_pid = 3 -- Process ID of Picotron's window manager and info bar

--- Reports a fatal error, logs the message and traceback, and exits the program.
--- @param message string: The format string for the error message
--- @param exit_code number: Optional custom exit code (default is 1)
--- @param ... any: Additional arguments to format the message
local function wtf(message, exit_code, ...)
   local exit_code = exit_code or 1
   local error_report = debug.traceback(string.format(message, ...), 2)

   send_message(wm_pid, {event = "report_error", content = "*wtf?!"})
   send_message(wm_pid, {event = "report_error", content = error_report})

   exit(exit_code)
end

--- Retrieves the process ID (PID) by process name.
--- @param name string: The name of the process to search for.
--- @return number: The process ID if found, or -1 if not found.
function get_pid_by_name(name)
   local processes = fetch("/ram/system/processes.pod")

   for i = 1, #processes do
      local process = processes[i]
      if (process.name == name) then
         -- Return the process ID if found
         return process.id
      end
   end

   return -1
end

--- Retrieves the current folder of the calling script
--- @return string
local function get_current_folder()
   local str = debug.getinfo(2, "S").source:sub(2)
   return str:match("(.*/)")
end

--- Attempts to resolve the full path of a module.
--- Adds ".lua" extension if necessary.
--- @param path string: The path to the module
--- @return string: The full path of the module
local function resolve_module_path(path)
   if not path:match("%.lua$") then
      return fullpath(path..".lua")
   end
   return fullpath(path)
end

-- Table to cache loaded modules to avoid reloading
local _LOADED = {}

-- Holds all the paths to search for modules
local _PATH = {get_current_folder()}

--- Adds a new path to the module search path
--- @param path string: The new path to be added
function add_module_path(path)
   table.insert(_PATH, path)
end

--- Clears all loaded modules from the cache, with an option to preserve specific modules.
--- This allows modules to be reloaded upon the next `require()` call, except for those marked as preserved.
--- Useful for reloading modules during testing or debugging, while retaining essential ones like log utilities.
--- @param preserved table: (Optional) A list of module names to preserve in the cache (e.g., {"log", "config"}).
function clear_module_cache(preserved)
   -- Iterate through the loaded modules cache (_LOADED)
   for module_name, _ in pairs(_LOADED) do
      local preserve = false -- Flag to determine if the module should be preserved

      -- Check if the module is in the list of preserved modules
      if preserved then
         for _, preserve_name in pairs(preserved) do
            if module_name == preserve_name then
               preserve = true
               break -- No need to check further if the module is already marked to preserve
            end
         end
      end

      -- If the module is not in the preserved list, remove it from the cache
      if not preserve then
         _LOADED[module_name] = nil
      end
   end
end

--- Loads and caches a Lua module, similar to the `require()` function.
--- If the module is already cached, it returns the cached version.
--- Otherwise, it resolves the module's path, fetches, compiles, and executes it.
--- The `alias` parameter allows you to load an alternative (mock) implementation
--- instead of the real module.
--- @param filename string: The name of the Lua module to load.
--- @param alias string: (Optional) An alternative name to use for caching or loading a mock module.
--- @return any: The result of the module's execution, typically a table containing functions or data.
function require(filename, alias)
   local full_filename, src
   local key = filename

   if alias then
      key = alias
   end

   if _LOADED[key] then
      return _LOADED[key]
   end

   for _, path in ipairs(_PATH) do
      full_filename = resolve_module_path(path..filename)

      src = fetch(full_filename)

      if type(src) == "string" then
         local func, err = load(src, "@"..full_filename, "t", _ENV)

         if not func then
            wtf("Error loading module '"..filename.."': "..err)
            return
         end

         _LOADED[key] = func() or true
         return _LOADED[key]
      end
   end

   wtf("Module '"..filename.."' not found in search paths.")
end
