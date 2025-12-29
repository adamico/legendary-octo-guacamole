-- Enemy spawning system
local Entities = require("src/entities")
local GameConstants = require("src/game/game_config")
local Spawner = {}

Spawner.indicator_sprite = SPAWNER_INDICATOR_SPRITE

function Spawner.update(world, room)
    -- Regular enemy spawning (room is in spawning state)
    if room and room.lifecycle:is("spawning") then
        room.spawn_timer -= 1
        if room.spawn_timer <= 0 then
            for _, pos in ipairs(room.enemy_positions) do
                Entities.spawn_enemy(world, pos.x, pos.y, pos.type)
            end
            room.lifecycle:spawn()
        end
    end

    -- Skull timer and spawning (for both active/locked and cleared combat rooms)
    if room and room.skull_timer and not room.skull_spawned then
        room.skull_timer -= 1
        if room.skull_timer <= 0 then
            -- If room is active (locked), ignore health check to add pressure
            local ignore_health = room.lifecycle:is("active")
            if Spawner.spawn_skull(world, room, ignore_health) then
                room.skull_spawned = true
            end
        end
    end
end

function Spawner.draw(room)
    if not room or not room.lifecycle:is("spawning") then return end

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
-- config: { wave_pattern = pattern } or legacy { enemies = { count, types } }
function Spawner.populate(room, player)
    -- Early exit if not in populated state or no config
    if not room or not room.lifecycle:is("populated") or not room.contents_config then return end

    local WavePatterns = require("src/world/wave_patterns")
    local RoomLayouts = require("src/world/room_layouts")

    -- Get room inner bounds once (in pixel space) for bounds checking
    local room_bounds = room:get_inner_bounds()
    local room_px = {
        x1 = room_bounds.x1 * GRID_SIZE,
        y1 = room_bounds.y1 * GRID_SIZE,
        x2 = (room_bounds.x2 + 1) * GRID_SIZE,
        y2 = (room_bounds.y2 + 1) * GRID_SIZE
    }

    -- Helper: Check if a single tile is valid for spawning
    local function is_tile_valid(tx, ty)
        -- Check tile is within room bounds
        if tx < room_bounds.x1 or tx > room_bounds.x2 or
           ty < room_bounds.y1 or ty > room_bounds.y2 then
            return false
        end

        -- Check if it's a floor tile (not pit or other solid)
        if not RoomLayouts.is_floor_tile(tx, ty) then return false end

        -- Direct pit tile check (for layouts without grid pattern data)
        local tile = mget(tx, ty)
        if tile == PIT_TILE then return false end

        -- Fast layout-based feature check (Rocks/Pits/Destructibles)
        if room.layout and room.layout.grid then
            local floor_rect = room:get_inner_bounds()
            local room_w = floor_rect.x2 - floor_rect.x1 + 1
            local room_h = floor_rect.y2 - floor_rect.y1 + 1
            local gx = tx - floor_rect.x1
            local gy = ty - floor_rect.y1

            local feature = RoomLayouts.get_feature_at(room.layout, gx, gy, room_w, room_h)
            if feature == "rock" or feature == "destructible" or feature == "pit" then
                return false
            end
        end

        return true
    end

    -- Helper: Check if a position is valid for spawning (check entity footprint)
    local function is_valid_spawn(px, py, etype)
        -- First check if position is within room pixel bounds
        if px < room_px.x1 or px + 16 > room_px.x2 or
           py < room_px.y1 or py + 16 > room_px.y2 then
            return false
        end

        local config = GameConstants.Enemy[etype or "Skulker"]
        if not config then return true end

        local w = config.hitbox_width or config.width or 16
        local h = config.hitbox_height or config.height or 16
        local ox = config.hitbox_offset_x or 0
        local oy = config.hitbox_offset_y or 0

        local x1 = flr((px + ox) / GRID_SIZE)
        local y1 = flr((py + oy) / GRID_SIZE)
        local x2 = flr((px + ox + w - 0.1) / GRID_SIZE)
        local y2 = flr((py + oy + h - 0.1) / GRID_SIZE)

        for ty = y1, y2 do
            for tx = x1, x2 do
                if not is_tile_valid(tx, ty) then return false end
            end
        end
        return true
    end

    -- Helper: Find nearest valid tile (within room bounds)
    local function nudge_to_valid(px, py, etype)
        if is_valid_spawn(px, py, etype) then return px, py end

        -- Search in expanding rings
        for r = 8, 48, 8 do
            for angle = 0, 0.875, 0.125 do -- 0 to 7/8 cycles (0 to 315 degrees)
                local nx = px + cos(angle) * r
                local ny = py + sin(angle) * r
                if is_valid_spawn(nx, ny, etype) then
                    return nx, ny
                end
            end
        end
        return nil
    end

    -- Pattern-based spawning
    if room.contents_config.wave_pattern then
        local pattern = room.contents_config.wave_pattern
        local calc_pos = WavePatterns.calculate_positions(pattern, room:get_inner_bounds())

        room.enemy_positions = {}
        for _, pos in ipairs(calc_pos) do
            local nx, ny = nudge_to_valid(pos.x, pos.y, pos.type)
            if nx then
                add(room.enemy_positions, {x = nx, y = ny, type = pos.type})
            end
        end

        -- Fallback to random if pattern completely failed
        if #room.enemy_positions > 0 then
            room.spawn_timer = 60
            return
        end
        Log.info("Pattern "..tostring(pattern.name).." failed to find valid positions, falling back to random")
    end

    -- Random spawning (Fallback or primary if no pattern)
    local enemy_config = room.contents_config.enemies
    -- If we came from a failed pattern, we need to create a config
    if not enemy_config then
        local pattern = room.contents_config.wave_pattern
        local difficulty = pattern and pattern.difficulty or 1
        enemy_config = {
            count = mid(2, difficulty * 2, 6),
            min_dist = 80,
            types = (difficulty == 1) and {"Skulker"} or {"Skulker", "Shooter"}
        }
    end

    if not enemy_config or not enemy_config.count or enemy_config.count <= 0 then return end

    local num_enemies = enemy_config.count
    local min_dist = enemy_config.min_dist or 96

    room.enemy_positions = {}
    local floor = room:get_inner_bounds()
    local attempts = 0
    local max_attempts = 500

    while #room.enemy_positions < num_enemies and attempts < max_attempts do
        attempts = attempts + 1

        -- Scale down min_dist if struggling to find spots
        local active_min_dist = min_dist
        if attempts > 200 then active_min_dist = min_dist * 0.7 end
        if attempts > 400 then active_min_dist = 32 end

        -- Pick random tile within floor bounds
        local tx = floor.x1 + flr(rnd(floor.x2 - floor.x1 + 1))
        local ty = floor.y1 + flr(rnd(floor.y2 - floor.y1 + 1))
        local rx = tx * GRID_SIZE
        local ry = ty * GRID_SIZE

        local etype = "Skulker"
        if enemy_config.types and #enemy_config.types > 0 then
            etype = enemy_config.types[flr(rnd(#enemy_config.types)) + 1]
        elseif rnd(1) < 0.4 then
            etype = "Shooter"
        end

        -- Check if valid floor position
        local nx, ny = nudge_to_valid(rx, ry, etype)
        if not nx then
            goto continue
        end

        -- Check distance from player
        local dx = nx - player.x
        local dy = ny - player.y
        if dx * dx + dy * dy > active_min_dist * active_min_dist then
            if Spawner.is_free_space(room, nx, ny) then
                table.insert(room.enemy_positions, {x = nx, y = ny, type = etype})
            end
        end
        ::continue::
    end

    if #room.enemy_positions > 0 then
        room.spawn_timer = 60 -- Default spawn delay
    end
end

-- Spawn skull at farthest corner from player (outside screen)
function Spawner.spawn_skull(world, room, ignore_health_check)
    if not room then return false end

    -- Get player position
    local player_x, player_y
    local player_entity
    world.sys("player", function(p)
        player_x = p.x
        player_y = p.y
        player_entity = p
    end)()

    -- If no player, don't spawn
    if not player_x then return false end

    -- Don't spawn if player is at full health (no idle regeneration to punish)
    -- UNLESS we are ignoring the health check (e.g. pressure in locked room)
    if not ignore_health_check and player_entity and player_entity.hp >= player_entity.max_hp then
        return false
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
    local skull = Entities.spawn_enemy(world, spawn_pos.x, spawn_pos.y, "Skull")
    room.skull_entity = skull -- Track for cleanup
    return true
end

return Spawner
