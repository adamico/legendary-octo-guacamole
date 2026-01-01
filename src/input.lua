-- Input module: consolidates all input handling
-- This is a top-level module (not an ECS system) that maps hardware input to entity properties
local GameConstants = require("src/game/game_config")

local Input = {}

-- Module state: stores current frame's shoot direction (read by shooter system)
Input.shoot_dir = {x = 0, y = 0}

-- Main input handler: reads movement and action buttons for all controllable entities
-- @param world - ECS world to query
function Input.read_input(world)
   -- Read shooting input once per frame (shared by all controllable entities)
   local shoot_dir_x = 0
   local shoot_dir_y = 0
   if btn(GameConstants.controls.aim_left) then shoot_dir_x = -1 end
   if btn(GameConstants.controls.aim_right) then shoot_dir_x = 1 end
   if btn(GameConstants.controls.aim_up) then shoot_dir_y = -1 end
   if btn(GameConstants.controls.aim_down) then shoot_dir_y = 1 end
   Input.shoot_dir.x = shoot_dir_x
   Input.shoot_dir.y = shoot_dir_y

   -- Update movement direction for controllable entities
   world:query({"controllable", "direction"}, function(ids, dir)
      for i = ids.first, ids.last do
         -- Movement Input
         local left = btn(GameConstants.controls.move_left)
         local right = btn(GameConstants.controls.move_right)
         local up = btn(GameConstants.controls.move_up)
         local down = btn(GameConstants.controls.move_down)

         local dx = 0
         local dy = 0
         if left then dx -= 1 end
         if right then dx += 1 end
         if up then dy -= 1 end
         if down then dy += 1 end

         dir.dir_x[i] = dx
         dir.dir_y[i] = dy
      end
   end)
end

return Input
