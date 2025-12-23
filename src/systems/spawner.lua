-- Enemy spawning system
local Entities = require("entities")

local Spawner = {}

Spawner.indicator_sprite = 207

function Spawner.update(world, room)
    -- Regular enemy spawning
    if room and not room.spawned then
        room.spawn_timer -= 1
        if room.spawn_timer <= 0 then
            for _, pos in ipairs(room.enemy_positions) do
                Entities.spawn_enemy(world, pos.x, pos.y, pos.type)
            end
            room.spawned = true
        end
    end

    -- Skull timer and spawning (only for cleared combat rooms)
    if room and room.skull_timer and not room.skull_spawned then
        room.skull_timer -= 1
        if room.skull_timer <= 0 then
            Spawner.spawn_skull(world, room)
            room.skull_spawned = true
        end
    end
end

function Spawner.draw(room)
    if not room or room.spawned then return end

    -- Blinking effect: toggle visibility every 15 frames, visible for 8
    if room.spawn_timer % 15 < 8 then
        for _, pos in ipairs(room.enemy_positions) do
            spr(Spawner.indicator_sprite, pos.x, pos.y)
        end
    end
end

-- Check if space is free for spawning
function Spawner.is_free_space(room, x, y)
    for _, pos in ipairs(room.enemy_positions) do
        local dx = x - pos.x
        local dy = y - pos.y
        if dx * dx + dy * dy < 16 * 16 then return false end
    end
    return true
end

-- Populate room with enemies based on configuration
-- config: { enemies = { count = N, min_dist = D, types = {...} } }
function Spawner.populate(room, player)
    -- Early exit if already spawned or no config
    if not room or room.spawned or not room.contents_config then return end

    local enemy_config = room.contents_config.enemies
    if not enemy_config or not enemy_config.count or enemy_config.count <= 0 then return end

    local num_enemies = enemy_config.count
    local min_dist = enemy_config.min_dist or 96

    room.enemy_positions = {}
    local floor = room:get_inner_bounds()
    local attempts = 0

    while #room.enemy_positions < num_enemies and attempts < 200 do
        attempts = attempts + 1

        -- Pick random tile within floor bounds
        local tx = floor.x1 + flr(rnd(floor.x2 - floor.x1 + 1))
        local ty = floor.y1 + flr(rnd(floor.y2 - floor.y1 + 1))
        local rx = tx * GRID_SIZE
        local ry = ty * GRID_SIZE

        -- Check distance from player
        local dx = rx - player.x
        local dy = ry - player.y
        if dx * dx + dy * dy > min_dist * min_dist then
            if Spawner.is_free_space(room, rx, ry) then
                local etype = "Skulker"
                -- Use configured types if available
                if enemy_config.types and #enemy_config.types > 0 then
                    etype = enemy_config.types[flr(rnd(#enemy_config.types)) + 1]
                else
                    -- Default fallback logic
                    if rnd(1) < 0.4 then etype = "Shooter" end
                end

                table.insert(room.enemy_positions, {x = rx, y = ry, type = etype})
            end
        end
    end

    if #room.enemy_positions > 0 then
        room.spawn_timer = 60 -- Default spawn delay
        room.spawned = false  -- Will set to true after timer
    else
        room.spawned = true   -- No enemies, consider spawned immediately
    end
end

-- Spawn skull at farthest corner from player (outside screen)
function Spawner.spawn_skull(world, room)
    if not room then return end

    -- Get player position
    local player_x, player_y
    world.sys("player", function(p)
        player_x = p.x
        player_y = p.y
    end)()

    -- If no player, don't spawn
    if not player_x then return end

    -- Don't spawn if player is at full health (no idle regeneration to punish)
    local player_entity
    world.sys("player", function(p) player_entity = p end)()
    if player_entity and player_entity.hp >= player_entity.max_hp then
        return
    end

    -- Calculate offscreen spawn positions (beyond screen edges relative to room center)
    local bounds = room:get_inner_bounds()
    local offset_pixels = 32 -- Spawn 32 pixels beyond visible screen area

    local center_x = (bounds.x1 + (bounds.x2 - bounds.x1) / 2) * GRID_SIZE
    local center_y = (bounds.y1 + (bounds.y2 - bounds.y1) / 2) * GRID_SIZE

    local corners = {
        {x = center_x - (SCREEN_WIDTH / 2) - offset_pixels, y = center_y - (SCREEN_HEIGHT / 2) - offset_pixels}, -- Top-left offscreen
        {x = center_x + (SCREEN_WIDTH / 2) + offset_pixels, y = center_y - (SCREEN_HEIGHT / 2) - offset_pixels}, -- Top-right offscreen
        {x = center_x - (SCREEN_WIDTH / 2) - offset_pixels, y = center_y + (SCREEN_HEIGHT / 2) + offset_pixels}, -- Bottom-left offscreen
        {x = center_x + (SCREEN_WIDTH / 2) + offset_pixels, y = center_y + (SCREEN_HEIGHT / 2) + offset_pixels}  -- Bottom-right offscreen
    }

    -- Find farthest corner from player
    local max_dist = 0
    local spawn_pos = corners[1]
    for _, corner in ipairs(corners) do
        local dx = corner.x - player_x
        local dy = corner.y - player_y
        local dist = dx * dx + dy * dy
        if dist > max_dist then
            max_dist = dist
            spawn_pos = corner
        end
    end

    -- Spawn skull at farthest corner
    local skull = Entities.spawn_skull(world, spawn_pos.x, spawn_pos.y)
    room.skull_entity = skull -- Track for cleanup

    Log.trace("Spawned skull at ("..spawn_pos.x..", "..spawn_pos.y..")")
end

return Spawner
