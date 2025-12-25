local function chaser_behavior(entity, player)
    local dx = player.x - entity.x
    local dy = player.y - entity.y
    local dist = sqrt(dx * dx + dy * dy)

    if dist > 0 then
        entity.vel_x = (dx / dist) * entity.speed
        entity.vel_y = (dy / dist) * entity.speed
        entity.dir_x = sgn(dx)
        entity.dir_y = sgn(dy)
    end
end

return chaser_behavior
