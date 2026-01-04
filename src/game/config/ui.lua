-- UI configurations: Hud, Minimap

local MutationsConfig = require("src/game/config/mutations")

return {
   Hud = {
      inventory = {
         x = 26,             -- Base X position from left
         y = 249,            -- Base Y position from top (lowered to make room for hearts)
         spacing_x = 30,     -- Horizontal spacing between items
         icon_size = 11,     -- Size of icons
         text_offset_x = 14, -- Text centered below icon
         text_offset_y = 2,  -- Text below icon (icon_size + 1px gap)
         text_color = 1,     -- White text
         shadow_color = 0,   -- Black shadow/outline
         sprites = {
            coins = 197,
            bombs = 196,
            keys = 198,
         }
      },
      mutations = {
         x = 254,            -- Base X position from left
         y = 249,            -- Base Y position from top (lowered to make room for hearts)
         spacing_x = 50,     -- Horizontal spacing between items
         icon_size = 11,     -- Size of icons
         text_offset_x = 20, -- Text centered below icon
         text_offset_y = 2,  -- Text below icon (icon_size + 1px gap)
         text_color = 1,     -- White text
         shadow_color = 0,   -- Black shadow/outline
         sprites = {
            Eggsaggerated = 28,
            Broodmother = 31,
            Pureblood = 57,
         }
      },
      combat_timer = {
         x = 10,
         y = 80,    -- Moved down
         color = 8, -- Red
      },
      health_bar = {
         x = 30,                  -- Centered in left half (240px wide): (240 - 10*18)/2 = 30
         y = 7,
         heart_sprite = 42,       -- Full Heart
         half_heart_sprite = 43,  -- Half Heart
         empty_heart_sprite = 56, -- Empty Heart
         heart_size = 16,         -- 16x16 sprite
         heart_spacing = 18,      -- 16 + 2px gap
         max_per_row = 10,        -- Max 10 hearts per row (~180px width)
         -- Heart sprite base colors (in luminance order): 7, 8, 24, 2
         -- Each palette maps: {color_for_7, color_for_8, color_for_24, color_for_2}
         colors = {
            normal = nil,               -- No swap needed (use original red)
            empty = nil,                -- Empty sprite (56) has its own colors
            overheal = {7, 28, 12, 16}, -- Blue hue equivalent
         }
      },
      xp_bar = {
         x = 254,          -- Horizontal position from left screen edge
         y = 10,           -- At screen bottom (overlap with wall)
         width = 200,      -- Bar width
         height = 9,       -- Bar height
         bg_color = 1,     -- Black background
         fill_color = 11,  -- Yellow fill
         border_color = 5, -- Dark gray border
         text_color = 7,   -- White level text
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
