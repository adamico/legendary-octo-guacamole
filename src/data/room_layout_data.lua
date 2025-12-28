-- Room Layout Data
-- ASCII grid definitions for room interior patterns
-- Separated from room_layouts.lua for cleaner data/code separation
--
-- GRID SYSTEM:
-- - 9×7 grid maps to 27×14 room interior (each cell = 3×2 tiles)
-- - cell_pattern array specifies how each feature instance is placed:
--   "f"  = full 3×2 block
--   "tl" = top-left single tile
--   "tm" = top-middle single tile
--   "tr" = top-right single tile
--   "bl" = bottom-left single tile
--   "bm" = bottom-middle single tile
--   "br" = bottom-right single tile
-- - Pattern cycles through features in reading order (left-to-right, top-to-bottom)

local LayoutData = {}

-- Feature legend (char → feature type)
LayoutData.FEATURE_LEGEND = {
   ["."] = "floor",        -- Normal floor tile
   ["R"] = "rock",         -- Solid rock obstacle
   ["P"] = "pit",          -- Pit (blocks walking, not projectiles)
   ["D"] = "destructible", -- Breakable obstacle
   ["W"] = "wall",         -- Interior wall (solid)
}

-- Cell pattern position offsets within 3×2 cell
-- Keys: position name, Values: {tile_offset_x, tile_offset_y, width, height}
LayoutData.CELL_POSITIONS = {
   tl = {0, 0, 1, 1}, -- top-left single tile
   tm = {1, 0, 1, 1}, -- top-middle single tile
   tr = {2, 0, 1, 1}, -- top-right single tile
   bl = {0, 1, 1, 1}, -- bottom-left single tile
   bm = {1, 1, 1, 1}, -- bottom-middle single tile
   br = {2, 1, 1, 1}, -- bottom-right single tile
   f  = {0, 0, 3, 2}, -- full 3×2 block
}

-- Grid dimensions
LayoutData.GRID_COLS = 9
LayoutData.GRID_ROWS = 7
LayoutData.CELL_WIDTH = 3  -- tiles per cell horizontally
LayoutData.CELL_HEIGHT = 2 -- tiles per cell vertically

-- Layout definitions
-- Each layout has:
--   room_types: table of room types this layout can appear in
--   layout_type: visual category name
--   floor_pattern: floor tile pattern
--   grid: ASCII grid (nil = pure floor) - 9 columns x 7 rows
--   cell_pattern: optional array of positions for each feature instance
LayoutData.Layouts = {
   -- OPEN layouts (used for special rooms)
   open = {
      room_types = {"start", "boss", "treasure", "shop", "combat"},
      layout_type = "open",
      floor_pattern = "random",
      grid = nil
   },

   -- COMBAT layouts - variety of obstacle patterns
   corners = {
      room_types = {"combat"},
      layout_type = "corners",
      floor_pattern = "random",
      grid = {
         "R.R...R.R",
         ".........",
         ".........",
         ".........",
         ".........",
         ".........",
         "R.R...R.R",
      }
   },

   cross_rocks = {
      room_types = {"combat"},
      layout_type = "cross",
      floor_pattern = "random",
      grid = {
         "...R.R...",
         ".........",
         "RR.....RR",
         ".........",
         "RR.....RR",
         ".........",
         "...R.R...",
      }
   },

   center_block = {
      room_types = {"combat"},
      layout_type = "center",
      floor_pattern = "random",
      cell_pattern = {
         "br", "f", "bl",
         "f", "f", "f",
         "tr", "f", "tl",
      },
      grid = {
         ".........",
         ".........",
         "...RRR...",
         "...RRR...",
         "...RRR...",
         ".........",
         ".........",
      }
   },

   pit_cross = {
      room_types = {"combat"},
      layout_type = "cross",
      floor_pattern = "random",
      cell_pattern = {
         "f",
         "br", "f", "bl",
         "f", "f",
         "tr", "f", "tl",
         "f",
      },
      grid = {
         ".........",
         "....P....",
         "...PPP...",
         "..P...P..",
         "...PPP...",
         "....P....",
         ".........",
      }
   },

   pit_corners = {
      room_types = {"combat"},
      layout_type = "corners",
      floor_pattern = "random",
      cell_pattern = {
         "br", "f", "f", "f", "f", "bl",
         "f", "f",
         "f", "f",
         "tr", "f", "f", "f", "f", "tl",
      },
      grid = {
         ".PPP.PPP.",
         ".P.....P.",
         ".........",
         ".........",
         ".........",
         ".P.....P.",
         ".PPP.PPP.",
      }
   },

   ring = {
      room_types = {"combat"},
      layout_type = "ring",
      floor_pattern = "random",
      cell_pattern = {
         "f", "f", "f",
         "br", "f", "f", "f", "bl",
         "f", "f", "f", "f", "f",
         "tr", "f", "f", "f", "tl",
         "f", "f", "f",
      },
      grid = {
         ".........",
         "...RRR...",
         "..RPPPR..",
         "..RPPPR..",
         "..RPPPR..",
         "...RRR...",
         ".........",
      }
   },

   scattered_rocks = {
      room_types = {"combat"},
      layout_type = "scattered",
      floor_pattern = "random",
      cell_pattern = {
         "tl", "tr",
         "bm",
         "tm", "tm",
         "f", "f",
         "bm", "bm",
         "tm",
         "bl", "br"
      },
      grid = {
         ".R.....R.",
         "....R....",
         "...R.R...",
         "...R.R...",
         "...R.R...",
         "....R....",
         ".R.....R.",
      }
   },

   destructible_corners = {
      room_types = {"combat"},
      layout_type = "corners",
      floor_pattern = "random",
      cell_pattern = {
         "f", "tl", "tr", "f",
         "f", "f",
         "f", "f",
         "f", "bl", "br", "f",
      },
      grid = {
         "DD.....DD",
         "D.......D",
         ".........",
         ".........",
         ".........",
         "D.......D",
         "DD.....DD",
      }
   },

   mixed = {
      room_types = {"combat"},
      layout_type = "mixed",
      floor_pattern = "random",
      cell_pattern = {
         "f", "f", "f", "f", "f", "f", "f", "f", "f", "f",
         "bm",
         "f", "f",
         "tm",
         "f", "f", "f", "f", "f", "f", "f", "f", "f", "f",
      },
      grid = {
         "R.......R",
         ".........",
         "....D....",
         "...P.P...",
         "....D....",
         ".........",
         "R.......R",
      }
   },

   corridor_vertical = {
      room_types = {"combat"},
      requires_no_doors = {"east", "west"},
      layout_type = "corridor",
      floor_pattern = "random",
      grid = {
         "PPP...PPP",
         "PPP...PPP",
         "PPP...PPP",
         "PPP...PPP",
         "PPP...PPP",
         "PPP...PPP",
         "PPP...PPP",
      }
   },

   corridor_horizontal = {
      room_types = {"combat"},
      requires_no_doors = {"north", "south"},
      layout_type = "corridor",
      floor_pattern = "random",
      cell_pattern = {
         "f", "f", "f", "f", "f", "f", "f", "f", "f", "f",
         "tm", "tm", "tm", "tm", "tm", "tm", "tm", "tm", "tm", "tm",
         "bm", "bm", "bm", "bm", "bm", "bm", "bm", "bm", "bm", "bm",
         "f", "f", "f", "f", "f", "f", "f", "f", "f", "f",
      },
      grid = {
         "PPPPPPPPP",
         "PPPPPPPPP",
         ".........",
         ".........",
         ".........",
         "PPPPPPPPP",
         "PPPPPPPPP",
      }
   },
}

return LayoutData
