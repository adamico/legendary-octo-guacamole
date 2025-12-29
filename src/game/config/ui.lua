-- UI configurations: Hud, Minimap

return {
   Hud = {
      inventory = {
         x = 10,             -- Base X position from left
         y = 16,             -- Base Y position from top (below health bar)
         spacing_y = 16,     -- Vertical spacing between items
         icon_size = 11,     -- Size of icons
         text_offset_x = 16, -- Text distance from icon left
         text_offset_y = 2,  -- Text vertical alignment
         text_color = 7,     -- White text
         shadow_color = 1,   -- Black shadow/outline
         sprites = {
            coins = 197,
            bombs = 196,
            keys = 198,
         }
      },
   },
   Minimap = {
      cell_size = 11,        -- Size of each room cell in pixels (10x10 sprite + padding)
      padding = 1,           -- Padding between cells
      margin_x = 26,         -- Distance from right screen edge
      margin_y = 24,         -- Distance from top screen edge (default position)
      margin_y_bottom = 24,  -- Distance from bottom screen edge (alternate position)
      viewport_w = 5,        -- Max visible rooms horizontally
      viewport_h = 5,        -- Max visible rooms vertically
      border_color = 5,      -- Dark gray for borders
      background_color = 21,
      visited_color = 6,     -- Light gray for visited rooms
      current_color = 7,     -- White for current room
      unexplored_color = 1,  -- Dark blue for unexplored but discovered
      icon_size = 10,        -- Special room icon sprite size
      overlap_margin_x = 32, -- Check x buffer
      overlap_margin_y = 16, -- Check y margin
      tween_duration = 15,   -- Frames to tween between positions
      icons = {              -- Special room sprites (10x10)
         start = 192,
         shop = 193,
         treasure = 194,
         boss = 195,
      },
   },
}
