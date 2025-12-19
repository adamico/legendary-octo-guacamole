local Systems = require("systems")

local Play = SceneManager:addState("Play")

world = eggs()
player = {}

local function spawn_player()
   local player = {
      x = 10 * 16,
      y = 10 * 16,
      width = 16,
      height = 16,
      -- Movement properties (BoI-style: instant response, almost no slide)
      accel = 1.2,
      max_speed = 2,
      friction = 0.5,
      vel_x = 0,
      vel_y = 0,
      sprite_index = GameConstants.Player.sprite_index_offset,
   }
   return world.ent("player,drawable,velocity,controllable,acceleration", player)
end

function Play:enteredState()
   Log.trace("Entered Play scene")
   player = spawn_player()
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
