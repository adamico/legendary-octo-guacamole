local SCREEN_WIDTH = 480

---@class CharData
---@field bmp Userdata
---@field width number
---@field height number
---@field ascent number
---@field offset number
---@field special? string

---@class FontData
---@field meta {name: string, author: string}
---@field chars table<string, CharData>

---@class FontConfig
---@field chars string[]
---@field special {undefined: Userdata, space?: Userdata}
---@field pod {bmp: Userdata}[]
---@field ascent number[]
---@field offset number[]
---@field meta {name?: string, author?: string}

---@class WrapOptions
---@field enabled boolean
---@field wrap_bounds {x: number, y: number, w: number, h: number}
---@field wrap_offscreen boolean

---@class RenderOptions
---@field size? number
---@field color? number
---@field kerning? number
---@field line_spacing? number
---@field wrap? WrapOptions

---@class Font
---@field font_data FontData
---@field cache table
local Font = {}
Font.__index = Font

---@param ud Userdata
---@param original number
---@param new number
---@return Userdata|nil
local function ud_replaceAll(ud, original, new)
   local width = ud:width()
   local height = ud:height()

   ---@type Userdata|nil
   local ud_clone = ud:copy()

   for y = 0, height - 1 do
      for x = 0, width - 1 do
         if ud_clone and ud_clone:get(x, y) == original then
            ud_clone:set(x, y, new)
         end
      end
   end

   return ud_clone
end

---Constructor method to initialize the font object
---@param font_config FontConfig
---@return Font
function Font:new(font_config)
   local fontObject = {}
   setmetatable(fontObject, Font)

   if not font_config.special.undefined then
      error("Fonts must specify at least an undefined character.")
   end

   fontObject.font_data = self:parseFont(font_config)

   return fontObject
end

---Method to parse the font structure
---@param font_resource FontConfig
---@return FontData
function Font:parseFont(font_resource)
   local characters = ""

   -- Turn a char array (2D) into a single long string.
   for char_index = 1, #font_resource.chars do
      if type(font_resource.chars[char_index]) ~= "string" then
         error(string.format(
            "2D string array has non-string type (expected: 'string', got '%s') at c[%s]",
            type(font_resource.chars[char_index]), char_index
         ))
      end
      characters = characters..font_resource.chars[char_index]
   end

   local font_glyphs = characters
   local char_data = {
      undefined = {
         bmp = font_resource.special.undefined,
         width = font_resource.special.undefined:width(),
         height = font_resource.special.undefined:height(),
         ascent = 0,
         offset = 0,
      },
      space = {
         bmp = font_resource.special.space or font_resource.special.undefined,
         width = (font_resource.special.space or font_resource.special.undefined):width(),
         height = (font_resource.special.space or font_resource.special.undefined):height(),
         ascent = 0,
         offset = 0,
      },
   }

   -- Loop through every font_char character
   for charIndex = 1, #font_glyphs do
      local character = string.sub(font_glyphs, charIndex, charIndex)   -- Lua indexing with sub for characters
      if character ~= " " then
         -- Save character info
         char_data[character] = {
            bmp = font_resource.pod[charIndex].bmp,
            width = font_resource.pod[charIndex].bmp:width(),
            height = font_resource.pod[charIndex].bmp:height(),
            ascent = font_resource.ascent[charIndex],
            offset = font_resource.offset[charIndex],
         }
      end
   end

   return {
      meta = {
         name = font_resource.meta.name or "No name",
         author = font_resource.meta.author or "No author"
      },
      chars = char_data
   }
end

---@param get_character string
---@param font_color? number
---@return CharData
function Font:character(get_character, font_color)
   font_color = font_color or 7
   if get_character == " " then
      return self.font_data.chars.space
   elseif get_character == "\n" then
      return {
         special = "newline",
         width = 0,
         height = 0,
         bmp = nil, -- Not used for newline
         ascent = 0,
         offset = 0
      }
   elseif not self.font_data.chars[get_character] then
      return self.font_data.chars.undefined
   else
      return self.font_data.chars[get_character]
   end
end

---@param character_string string
---@return CharData[]
function Font:chars(character_string)
   local characters = {}
   for char_index = 1, #character_string do
      table.insert(characters, self:character(string.sub(character_string, char_index, char_index)))
   end
   return characters
end

---@param font_color number
---@return table<string, CharData>
function Font:recolored(font_color)
   local function recolor_chars(target_color)
      local characters = self.font_data.chars

      for char_index, char_value in pairs(characters) do
         -- CHANGE THIS 7 TO THE COLOR THE FONT IS IN IN THE SPRITE EDITOR
         characters[char_index] = char_value
         local replaced = ud_replaceAll(characters[char_index].bmp, 7, target_color)
         if replaced ~= nil then
            characters[char_index].bmp = replaced
         end
      end

      return characters
   end

   -- Cache the recolered versions of the font.
   self.cache = self.cache or {}
   self.cache.colored = self.cache.colored or {}
   self.cache.colored[font_color] = self.cache.colored[font_color] or recolor_chars(font_color)

   return self.cache.colored[font_color]
end

---@param x number
---@param y number
---@param characters CharData[]
---@param options? RenderOptions
local function renderChars(x, y, characters, options)
   options = options or {}
   options.size = options.size or 1
   options.color = options.color or 7
   options.kerning = options.kerning or 1
   options.line_spacing = options.line_spacing or 2
   options.wrap = options.wrap or {
      enabled = false,
      wrap_bounds = {x = 0, y = 0, w = 100, h = 100},
      wrap_offscreen = true
   }

   local x_offset = 0
   local y_offset = 0
   local running_max_height = 0
   local size = options.size
   local wrap_enabled = options.wrap.enabled == true
   local wrap_bounds = options.wrap.wrap_bounds
   local wrap_offscreen = options.wrap.wrap_offscreen == true
   local kerning = options.kerning
   local line_spacing = options.line_spacing

   -- Enable clipping if wrap is enabled
   if wrap_enabled then
      clip(wrap_bounds.x, wrap_bounds.y, wrap_bounds.w, wrap_bounds.h)
   end

   for _, char_value in ipairs(characters) do
      if char_value.special == "newline" then
         y_offset = y_offset + running_max_height + line_spacing
         x_offset = 0
         running_max_height = 0
      else
         local scaled_width = char_value.width * size
         local scaled_height = char_value.height * size
         local scaled_offset = char_value.offset * size
         local scaled_ascent = char_value.ascent * size
         local scaled_kerning = kerning * size

         if scaled_height > running_max_height then
            running_max_height = scaled_height
         end

         local recolored = ud_replaceAll(char_value.bmp, 7, options.color)
         if recolored == nil then
            recolored = char_value.bmp
         end

         -- Check for normal wrapping if enabled
         if (x + x_offset >= wrap_bounds.w - scaled_width) and wrap_enabled then
            y_offset = y_offset + running_max_height + line_spacing
            x_offset = 0
            running_max_height = 0
         end

         -- Check for offscreen wrapping if enabled
         if wrap_offscreen and (x + x_offset + scaled_width >= SCREEN_WIDTH) then
            y_offset = y_offset + running_max_height + line_spacing
            x_offset = 0
            running_max_height = 0
         end

         -- Draw the sprite with consistent scaling
         sspr(recolored, 0, 0, char_value.width, char_value.height, x + x_offset, y + (y_offset - scaled_ascent), scaled_width, scaled_height)

         -- Update x-offset by width, scaled kerning, and offset
         x_offset = x_offset + (scaled_width - scaled_offset + scaled_kerning)
      end
   end

   -- Reset the clipping bounds
   clip()
end

---@param text string
---@param x number
---@param y number
---@param color? number
---@param size? number
---@param options? RenderOptions
function Font:draw(text, x, y, color, size, options)
   options = options or {}
   options.color = color or 7
   options.size = size or 1

   -- Resolve the characters for text
   local characterSet = self:chars(text)

   -- Render the text
   renderChars(x, y, characterSet, options)
end

return Font
