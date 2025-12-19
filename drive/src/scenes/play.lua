local Systems = require("systems")
local Entities = require("entities")

local Play = SceneManager:addState("Play")

world = eggs()
player = {}

function Play:enteredState()
   Log.trace("Entered Play scene")
   player = Entities.spawn_player(world, 10 * 16, 10 * 16)
end

function Play:update()
   world.sys("controllable", Systems.controllable)()
   world.sys("acceleration", Systems.acceleration)()
   world.sys("velocity", Systems.velocity)()
end

function Play:draw()
   cls(0)
   clip(7 * 16, 16, 12 * 16, 11 * 16)
   rectfill(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, 21)
   clip()
   map()
   world.sys("drawable", Systems.drawable)()
end

function Play:exitedState()
   Log.trace("Exited Play scene")
end

return Play
