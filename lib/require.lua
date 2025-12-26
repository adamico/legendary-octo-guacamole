--[[
   Simple require - path-based module loading with caching
   Loads modules relative to cart root. Supports:
   - Direct files: require("lib/middleclass") -> lib/middleclass.lua
   - Directories:  require("scenes") -> scenes/init.lua
]]

local _LOADED = {}

function require(filename)
   -- Return cached module if already loaded
   if _LOADED[filename] then
      return _LOADED[filename]
   end

   -- Try direct file path first
   local path = filename:gsub("%.lua$", "")..".lua"
   local src = fetch(path)

   -- If not found, try as directory with init.lua
   if type(src) ~= "string" then
      local init_path = filename.."/init.lua"
      src = fetch(init_path)
      if type(src) == "string" then
         path = init_path
      end
   end

   -- Error if module not found
   if type(src) ~= "string" then
      local error_msg = "Module '"..filename.."' not found"
      printh(error_msg)
      error(error_msg)
   end

   -- Compile and execute module
   local func, err = load(src, "@"..path, "t", _ENV)
   if not func then
      local error_msg = "Error loading '"..filename.."': "..err
      printh(error_msg)
      error(error_msg)
   end

   -- Cache and return result
   _LOADED[filename] = func() or true
   return _LOADED[filename]
end
