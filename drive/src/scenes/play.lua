local Play = SceneManager:addState("Play")

world = eggs()
player = {}

local function spawn_player()
   local player = {
      x = 10 * 16,
      y = 10 * 16,
      width = 16,
      height = 16,
      speed = 2,
      speed_x = 0,
      speed_y = 0,
      sprite_index = GameConstants.Player.sprite_index_offset,
   }
   return world.ent("player,drawable,velocity,controllable", player)
end

local draw_entity = function(entity)
   spr(t() * 30 % 30 < 15 and entity.sprite_index or entity.sprite_index + 1, entity.x, entity.y)
end

function Play:enteredState()
   Log.trace("Entered Play scene")
   player = spawn_player()
end

function Play:update()
   world.sys("controllable", function(entity)
      local left = btn(GameConstants.controls.move_left)
      local right = btn(GameConstants.controls.move_right)
      local up = btn(GameConstants.controls.move_up)
      local down = btn(GameConstants.controls.move_down)

      -- Determine direction as unit values
      local dx = 0
      local dy = 0

      if left then dx = -1 end
      if right then dx = 1 end
      if up then dy = -1 end
      if down then dy = 1 end

      -- Normalize speed for diagonal movement (ceil = slightly faster diagonals)
      local speed = entity.speed
      if dx ~= 0 and dy ~= 0 then
         speed = ceil(speed * 0.7071)
      end

      entity.speed_x = dx * speed
      entity.speed_y = dy * speed
   end)()

   world.sys("velocity", function(entity)
      entity.x += entity.speed_x
      entity.y += entity.speed_y
   end)()
end

function Play:draw()
   cls(0)
   clip(7 * 16, 16, 12 * 16, 11 * 16)
   rectfill(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, 21)
   clip()
   map()
   world.sys("drawable", draw_entity)()
end

function Play:exitedState()
   Log.trace("Exited Play scene")
end

return Play
