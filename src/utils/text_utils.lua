-- Text utilities for P8SCII and formatting
local TextUtils = {}

--- Build a p8scii string with an outline for visibility
-- Format: \^o{outline_color}{neighbor_bits}{text}
-- @param text The text to outline
-- @param outline_color The color index for the outline (default 0)
-- @param neighbor_bits Bitmask for neighbors (default "5a" - top, bottom, left, right)
-- @return The formatted P8SCII string
function TextUtils.get_outlined_text(text, outline_color, neighbor_bits)
   outline_color = outline_color or 0
   neighbor_bits = neighbor_bits or "5a"
   local hex_col = string.format("%x", outline_color)
   return string.format("\^o%s%s%s", hex_col, neighbor_bits, text)
end

--- Print text with an outline, handling palt(0, false) automatically
-- @param text The text to print
-- @param x X coordinate
-- @param y Y coordinate
-- @param color Main text color
-- @param outline_color Outline color (default 0)
-- @param neighbor_bits Bitmask for neighbors (default "5a")
function TextUtils.print_outlined(text, x, y, color, outline_color, neighbor_bits)
   local text_str = TextUtils.get_outlined_text(text, outline_color, neighbor_bits)
   palt(0, false)
   print(text_str, x, y, color)
   palt()
end

return TextUtils
