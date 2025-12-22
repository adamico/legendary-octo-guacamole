local RoomManager = {}

-- Current room state
RoomManager.clip = nil
RoomManager.pixels = nil

-- Initialize a room
-- For now we use the hardcoded clip values from play.lua
-- In the future this could take a room ID or definition
function RoomManager.init()
   -- Standard room size in tiles
   RoomManager.clip = {
      x = 7,
      y = 3,
      w = 12,
      h = 11
   }

   -- Convert to pixels for rendering/clipping
   RoomManager.pixels = {
      x = RoomManager.clip.x * GRID_SIZE,
      y = RoomManager.clip.y * GRID_SIZE,
      w = RoomManager.clip.w * GRID_SIZE,
      h = RoomManager.clip.h * GRID_SIZE
   }
end

-- Draw the room background
function RoomManager.draw()
   if not RoomManager.pixels then return end

   clip(RoomManager.pixels.x, RoomManager.pixels.y, RoomManager.pixels.w, RoomManager.pixels.h)
   rectfill(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, 5) -- Fill with map background color
   clip()
end

return RoomManager
