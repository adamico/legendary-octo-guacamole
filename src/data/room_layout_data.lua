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
   ["."] = "floor",          -- Normal floor tile
   ["R"] = "rock",           -- Solid rock obstacle
   ["P"] = "pit",            -- Pit (blocks walking, not projectiles)
   ["D"] = "destructible",   -- Breakable obstacle
   ["W"] = "wall",           -- Interior wall (solid)
   ["C"] = "chest",          -- Normal chest (drops 1-3 pickups)
   ["L"] = "locked_chest",   -- Locked chest (requires key, drops 2-6 pickups)
   ["S"] = "shop_item",      -- Shop item pedestal (purchasable)
   ["N"] = "no_spawn",       -- No enemy spawn zone (walkable, blocks spawns)
   ["T"] = "treasure_chest", -- Treasure chest (drops mutation)
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

-- Bitmask bit positions for 3×2 cell (6 tiles):
-- +---+---+---+
-- | 1 | 2 | 4 |   (top row: bits 0, 1, 2)
-- +---+---+---+
-- | 8 |16 |32 |   (bottom row: bits 3, 4, 5)
-- +---+---+---+
-- Use in cell_pattern: 63 = full block, 7 = top row, 56 = bottom row
LayoutData.BITMASK_POSITIONS = {
   {x = 0, y = 0}, -- bit 0 (value 1): top-left
   {x = 1, y = 0}, -- bit 1 (value 2): top-middle
   {x = 2, y = 0}, -- bit 2 (value 4): top-right
   {x = 0, y = 1}, -- bit 3 (value 8): bottom-left
   {x = 1, y = 1}, -- bit 4 (value 16): bottom-middle
   {x = 2, y = 1}, -- bit 5 (value 32): bottom-right
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
      room_types = {"start", "boss", "treasure", "combat"},
      layout_type = "open",
      floor_pattern = "random",
      grid = nil
   },

   treasure = {
      room_types = {"treasure"},
      layout_type = "treasure",
      floor_pattern = "random",
      cell_pattern = {"bm"},
      grid = {
         ".........",
         ".........",
         ".........",
         "....T....",
         ".........",
         ".........",
         ".........",
      }
   },

   -- SHOP layout - 3 item pedestals
   shop_layout = {
      room_types = {"shop"},
      layout_type = "shop",
      floor_pattern = "random",
      cell_pattern = {"bm", "bm", "bm"},
      grid = {
         ".........",
         ".........",
         ".........",
         "..S.S.S..",
         ".........",
         ".........",
         ".........",
      }
   },

   -- COMBAT layouts - variety of obstacle patterns
   corners = {
      room_types = {"combat"},
      layout_type = "corners",
      floor_pattern = "random",
      cell_pattern = {
         "f", 16, "f", "f", 16, "f",
         2, 2,
         16, 16,
         "f", 2, "f", "f", 2, "f",
      },
      grid = {
         "RCR...RLR",
         ".R.....R.",
         ".........",
         ".........",
         ".........",
         ".R.....R.",
         "RLR...RCR",
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
         "f", 16, "f",
         "tr", "f", "tl",
      },
      grid = {
         ".........",
         ".........",
         "...RRR...",
         "...RLR...",
         "...RRR...",
         ".........",
         ".........",
      }
   },

   diagonal_rocks = {
      room_types = {"combat"},
      layout_type = "diagonal",
      floor_pattern = "random",
      -- Bitmask 33 = 0b100001 = top-left + bottom-right tiles
      cell_pattern = {
         33, 33,
         16,
         33, 33,
      },
      grid = {
         "R.......R",
         ".........",
         ".........",
         "....L....",
         ".........",
         ".........",
         "R.......R",
      }
   },

   pit_cross = {
      room_types = {"combat"},
      layout_type = "cross",
      floor_pattern = "random",
      cell_pattern = {
         56,
         "br", "f", "bl",
         "f", "f", 16, "f", "f",
         "tr", "f", "tl",
         7,
      },
      grid = {
         ".........",
         "....P....",
         "...PPP...",
         "..RNCNR..",
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
         56, 56, 56,
         36, "f", "f", "f", 9,
         36, "f", 16, "f", 9,
         36, "f", "f", "f", 9,
         7, 7, 7,
      },
      grid = {
         ".........",
         "...RRR...",
         "..RPPPR..",
         "..RNLNR..",
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
         "tm", "f", "tm",
         "f", 16, "f",
         "bm", "f", "bm",
         "tm",
         "bl", "br"
      },
      grid = {
         ".R.....R.",
         "....R....",
         "...RNR...",
         "...RCR...",
         "...RNR...",
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
         "f", "f",
         "bm",
         "f", "bm", "f",
         "tm",
         "f", "f",
      },
      grid = {
         "R.......R",
         ".........",
         "....D....",
         "...PLP...",
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
         "f", "f", "f", "f", "f", "f", "f", "f", "f",
         "tm", "tm", "tm", "tm", "tm", "tm", "tm", "tm", "tm",
         "bm", "bm", "bm", "bm", "bm", "bm", "bm", "bm", "bm",
         "f", "f", "f", "f", "f", "f", "f", "f", "f",
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
