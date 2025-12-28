-- Input module: consolidates all input handling
-- This is a top-level module (not an ECS system) that maps hardware input to entity properties
local GameConstants = require("src/game/game_config")

local Input = {}

-- Main input handler: reads movement and action buttons
-- @param entity - Entity with controllable tag
function Input.read_input(entity)
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

   entity.dir_x = dx
   entity.dir_y = dy

   -- Action/Link Input (Shooting)
   local shoot_dir_x = 0
   local shoot_dir_y = 0
   if btn(GameConstants.controls.aim_left) then shoot_dir_x = -1 end
   if btn(GameConstants.controls.aim_right) then shoot_dir_x = 1 end
   if btn(GameConstants.controls.aim_up) then shoot_dir_y = -1 end
   if btn(GameConstants.controls.aim_down) then shoot_dir_y = 1 end

   entity.shoot_dir_x = shoot_dir_x
   entity.shoot_dir_y = shoot_dir_y
end

return Input
