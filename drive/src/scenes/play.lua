local Systems = require("systems")
local Entities = require("entities")

local Play = SceneManager:addState("Play")

local ROOM_CLIP = {
   x = 7 * 16,
   y = 16,
   w = 12 * 16,
   h = 11 * 16
}

world = eggs()
player = {}

local function draw_room()
   clip(ROOM_CLIP.x, ROOM_CLIP.y, ROOM_CLIP.w, ROOM_CLIP.h)
   rectfill(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, 5)
   clip()
end

function Play:enteredState()
   Log.trace("Entered Play scene")
   -- Initialize extended palette colors 32-63 for variants
   Systems.init_extended_palette()
   -- Initialize spotlight color table for lighting effects
   Systems.init_spotlight()
   player = Entities.spawn_player(world, 10 * 16, 10 * 16)
end

function Play:update()
   world.sys("controllable", Systems.controllable)()
   world.sys("acceleration", Systems.acceleration)()
   world.sys("velocity", Systems.velocity)()
   world.sys("drawable,sprite", Systems.change_sprite)()
end

function Play:draw()
   cls(0)
   draw_room()
   map()
   -- Draw spotlight first (brightens background)
   world.sys("spotlight", function(entity) Systems.draw_spotlight(entity, ROOM_CLIP) end)()
   -- Then shadow and player on top
   world.sys("shadow", Systems.draw_shadow)()
   world.sys("drawable", Systems.drawable)()
end

function Play:exitedState()
   Log.trace("Exited Play scene")
end

return Play
