-- Tile and world constants
-- Global tile IDs, autotiling, room features

SCREEN_WIDTH = 480
SCREEN_HEIGHT = 270
GRID_SIZE = 16
EMPTY_TILE = 0
DOOR_OPEN_TILE = 86
DOOR_BLOCKED_TILE = 71
WALL_TILE = 140

-- Lighting and Shadow constants
LIGHTING_SPOTLIGHT_COLOR = 33
LIGHTING_SHADOW_COLOR = 32

-- Autotiling constants
WALL_TILE_CORNER_TL = 64                             -- A: top-left corner
WALL_TILE_CORNER_TR = 68                             -- B: top-right corner
WALL_TILE_CORNER_BL = 96                             -- C: bottom-left corner
WALL_TILE_CORNER_BR = 100                            -- D: bottom-right corner
WALL_TILE_HORIZONTAL = {65, 66, 67, 97, 98, 99, 121} -- H: horizontal wall variants
WALL_TILE_VERTICAL = {72, 80, 88, 76, 84, 92}        -- V: vertical wall variants
-- Inner corner tiles (for walls between adjacent rooms with 2 diagonal floors)
WALL_TILE_INNER_TOP = 137                            -- 2 diagonals on top (TL + TR): inner corner pointing down
WALL_TILE_INNER_BOTTOM = 145                         -- 2 diagonals on bottom (BL + BR): inner corner pointing up
WALL_TILE_INNER_RIGHT = 116                          -- 2 diagonals on right (TR + BR): inner corner pointing left
WALL_TILE_INNER_LEFT = 115                           -- 2 diagonals on left (TL + BL): inner corner pointing right
-- TODO: readd floor tiles when floor autotiling is implemented
FLOOR_TILES = {73}                                   -- , 74, 75, 81, 82, 83, 89, 90, 91}   -- F: floor variants

-- Door frame tiles
DOOR_FRAME_H_TOP = {77, 93, 123, 124, 148, 153} -- Horizontal door top frame
DOOR_FRAME_H_BOTTOM = {107, 108, 129, 132}      -- Horizontal door bottom frame
DOOR_FRAME_V_LEFT = {117, 122, 138, 141, 146}   -- Vertical door left frame
DOOR_FRAME_V_RIGHT = {114, 120, 136, 139, 144}  -- Vertical door right frame

-- Room feature tiles (for layout carving)
ROCK_TILES = {134, 135, 142, 143}         -- R: solid rock obstacles
PIT_TILE = 85                             -- P: pit (blocks walking, not projectiles)
DESTRUCTIBLE_TILES = {150, 151, 158, 159} -- D: breakable obstacles
CHEST_TILE = 166                          -- C: normal chest
LOCKED_CHEST_TILE = 167                   -- L: locked chest

-- Feature type flags (for collision logic)
SOLID_FLAG = 0
FEATURE_FLAG_PIT = 1 -- allows projectiles to pass

-- Collision system constants
TILE_EDGE_TOLERANCE = 0.001    -- Small buffer to prevent floating-point edge cases
DOOR_GUIDANCE_MULTIPLIER = 1.5 -- Speed multiplier for nudging player toward doors
SPATIAL_GRID_CELL_SIZE = 64    -- Spatial partitioning cell size in pixels

-- Skull spawn timers
SKULL_SPAWN_TIMER = 420
SKULL_SPAWN_LOCKED_TIMER = 1800

-- Spawner indicator sprite
SPAWNER_INDICATOR_SPRITE = 45

-- Broken egg sprite constant
BROKEN_EGG_SPRITE = 27
-- Note: These are globals, no return needed
