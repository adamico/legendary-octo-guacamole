-- Text utilities for P8SCII and formatting
local TextUtils = {}

--- Build a p8scii string with an outline for visibility
--- Format: \^o{outline_color}{neighbor_bits}{text}
--- @param text string The text to outline
--- @param outline_color number The color index for the outline (default 0)
--- @param neighbor_bits string Bitmask for neighbors (default "5a" - top, bottom, left, right)
--- @return string The formatted P8SCII string
function TextUtils.get_outlined_text(text, outline_color, neighbor_bits)
   outline_color = outline_color or 0
   neighbor_bits = neighbor_bits or "5a"
   local hex_col = string.format("%x", outline_color)
   return string.format("\^o%s%s%s", hex_col, neighbor_bits, text)
end

--- Print text with an outline, handling palt(0, false) automatically
--- @param text string
--- @param x number X coordinate
--- @param y number Y coordinate
--- @param color number Main text color
--- @param outline_color number Outline color (default 0)
--- @param neighbor_bits string Bitmask for neighbors (default "5a")
function TextUtils.print_outlined(text, x, y, color, outline_color, neighbor_bits)
   local text_str = TextUtils.get_outlined_text(text, outline_color, neighbor_bits)
   palt(0, false)
   print(text_str, x, y, color)
   palt()
end

--- Print with custom sprite fonts
--- @param text string
--- @param x number
--- @param y number
--- @param scale number
--- @param color number
--- @param options? table kerning = int?,
---     line_spacing = int?,
---     wrap = {
---         enabled = bool?,
---         wrap_bounds = {x = int, y = int, w = int, h = int}?,
---         wrap_offscreen = bool?,
---     }?
function TextUtils.fprint(font_object, text, x, y, scale, color, options)
   font_object:draw(text, x, y, scale, color, options)
end

return TextUtils
