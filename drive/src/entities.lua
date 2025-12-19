-- Entities module: entity factory functions
local Entities = {}

-- Create a player entity
function Entities.spawn_player(world, x, y)
    local player = {
        x = x,
        y = y,
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

return Entities
