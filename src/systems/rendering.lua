-- Rendering system: core entity drawing
-- Focused on sprite drawing, layer rendering, and palette swaps

local qsort = require("lib/qsort")
local Effects = require("src/systems/effects")
local Rotator = require("src/systems/sprite_rotator")

local Rendering = {}

-- Internal sprite drawer (combines flash check and standard drawing)
local function draw_sprite(entity)
    local was_flashing = entity.flash_timer and entity.flash_timer > 0
    Effects.update_flash(entity)

    -- Actual drawing
    local flip_x = entity.flip_x or entity.flip or false
    local flip_y = entity.flip_y or false
    local sx = entity.x + (entity.sprite_offset_x or 0)
    local sy = entity.y + (entity.sprite_offset_y or 0)

    -- Check for death state to apply procedural effects
    if entity.fsm and entity.fsm:is("death") then
        local t = entity.anim_timer or 0
        local max_t = 30 -- assume 30 frame death
        local p = min(t / max_t, 1.0)

        -- Shake
        sx = sx + rnd(2) - 1
        sy = sy + rnd(2) - 1

        -- Flash/Palette effects
        if t < 4 then
            -- Initial white flash
            for i = 1, 15 do pal(i, 7) end
            for i = 32, 63 do pal(i, 7) end
        else
            -- Flicker breakdown
            if flr(t / 4) % 2 == 0 then
                pal(6, 8)  -- light gray -> red
                pal(5, 2)  -- dark gray -> purple
                pal(13, 2) -- purple -> purple
            end
            -- Fade out near end
            if p > 0.8 then
                -- dithering or just disappearing handled by size
            end
        end

        -- Procedural Stretch/Squash using sspr
        local n = entity.sprite_index or 0
        local w = entity.width or 16
        local h = entity.height or 16

        -- Squash vertically, spread horizontally
        local target_h = h * (1 - p)
        local target_w = w * (1 + p * 1.5)

        -- Keep feet anchored (draw_y adjusts as height shrinks)
        local draw_x = sx - (target_w - w) / 2
        local draw_y = sy + (h - target_h)

        -- Use sspr with sprite number directly (Picotron style)
        sspr(n, 0, 0, w, h, draw_x, draw_y, target_w, target_h, flip_x, flip_y)

        pal() -- Reset palette
        return
    end

    -- Check for composite sprite (top + bottom halves)
    if entity.sprite_top ~= nil and entity.sprite_bottom ~= nil then
        -- Use dynamic split_row (defaults to height/2)
        local width = entity.width or 16
        local height = entity.height or 16
        local split_row = entity.split_row or flr(height / 2)
        local bottom_height = height - split_row

        -- Draw top half
        sspr(
            entity.sprite_top,
            0, 0,
            width, split_row,
            sx, sy,
            width, split_row,
            flip_x, flip_y
        )
        -- Draw bottom half
        sspr(
            entity.sprite_bottom,
            0, split_row,
            width, bottom_height,
            sx, sy + split_row,
            width, bottom_height,
            flip_x, flip_y
        )
    else
        -- Standard single sprite
        local drawable = entity.sprite_index
        if entity.rotation_angle and entity.rotation_angle ~= 0 then
            drawable = Rotator.get(entity.sprite_index, entity.rotation_angle)
        end
        spr(drawable, sx, sy, flip_x, flip_y)
    end

    if was_flashing then
        pal(0) -- Reset palette
    end
end

-- Apply palette swaps for an entity
local function apply_palette_swaps(entity)
    if not entity.palette_swaps then return end

    for _, swap in ipairs(entity.palette_swaps) do
        pal(swap.from, swap.to)
    end
end

-- Draws all entities matching 'tags'. Optionally sorts them by Y position.
-- @param world - ECS world
-- @param tags - Tag string to query
-- @param sorted - Whether to Y-sort entities before drawing
function Rendering.draw_layer(world, tags, sorted)
    if sorted then
        local entities = {}
        world.sys(tags, function(e)
            add(entities, e)
        end)()

        -- Sort by Y position (bottom of sprite)
        qsort(entities, function(a, b)
            local ay = a.y + (a.height or 16)
            local by = b.y + (b.height or 16)
            return ay < by
        end)

        for i = 1, #entities do
            draw_sprite(entities[i])
        end
    else
        world.sys(tags, draw_sprite)()
    end
end

-- Apply palette swaps for all palette_swappable entities
-- @param world - ECS world
function Rendering.apply_palette_swaps(world)
    world.sys("palette_swappable", apply_palette_swaps)()
end

return Rendering
