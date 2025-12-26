-- Input system: consolidates all input handling
local GameConstants = require("src/constants")

local Input = {}

-- Main input handler: reads movement and action buttons
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
    local sx = 0
    local sy = 0
    if btn(GameConstants.controls.shoot_left) then sx = -1 end
    if btn(GameConstants.controls.shoot_right) then sx = 1 end
    if btn(GameConstants.controls.shoot_up) then sy = -1 end
    if btn(GameConstants.controls.shoot_down) then sy = 1 end

    entity.shoot_dir_x = sx
    entity.shoot_dir_y = sy
end

return Input
