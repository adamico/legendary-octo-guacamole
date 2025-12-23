local GameConstants = require("constants")
local Collision = require("collision")
local qsort = require("qsort")
local Effects = require("effects")
local Rotator = require("systems/sprite_rotator")

local Rendering = {}

Rendering.SPOTLIGHT_COLOR = 33
Rendering.SHADOW_COLOR = 32

local spotlight_initialized = false

function Rendering.init_extended_palette()
    local base_colors = {
        [0] = 0x000000,
        [1] = 0x1d2b53,
        [2] = 0x7e2553,
        [3] = 0x008751,
        [4] = 0xab5236,
        [5] = 0x5f574f,
        [6] = 0xc2c3c7,
        [7] = 0xfff1e8,
        [8] = 0xff004d,
        [9] = 0xffa300,
        [10] = 0xffec27,
        [11] = 0x00e436,
        [12] = 0x29adff,
        [13] = 0x83769c,
        [14] = 0xff77a8,
        [15] = 0xffccaa
    }

    for i = 0, 15 do
        local c = base_colors[i]
        local r = (c >> 16) & 0xff
        local g = (c >> 8) & 0xff
        local b = c & 0xff

        -- Lighter variant (50% toward white)
        local lr = flr(r + (255 - r) * 0.02)
        local lg = flr(g + (255 - g) * 0.02)
        local lb = flr(b + (255 - b) * 0.02)
        local light_argb = 0xff000000 | (lr << 16) | (lg << 8) | lb
        pal(32 + i, light_argb, 2)

        -- Darker variant (50% toward black)
        local dr = flr(r * 0.5)
        local dg = flr(g * 0.5)
        local db = flr(b * 0.5)
        local dark_argb = 0xff000000 | (dr << 16) | (dg << 8) | db
        pal(48 + i, dark_argb, 2)
    end
end

function Rendering.init_spotlight()
    if spotlight_initialized then return end
    Rendering.reset_spotlight()
    spotlight_initialized = true
end

function Rendering.reset_spotlight()
    local spotlight_row_address = 0x8000 + Rendering.SPOTLIGHT_COLOR * 64
    local shadow_row_address = 0x8000 + Rendering.SHADOW_COLOR * 64

    for target_col = 0, 63 do
        local bright_col, dark_col

        bright_col = target_col
        dark_col = target_col

        if target_col <= 15 then
            bright_col = 32 + target_col
            dark_col = 48 + target_col
        elseif target_col >= 32 and target_col <= 47 then
            local base = target_col - 32
            dark_col = 48 + base
        elseif target_col >= 48 and target_col <= 63 then
            local base = target_col - 48
            bright_col = base
        end

        poke(spotlight_row_address + target_col, bright_col)
        poke(shadow_row_address + target_col, dark_col)
    end

    poke(0x550b, 0x3f)
end

-- Sprite system: update sprite based on direction
function Rendering.change_sprite(entity)
    if entity.fsm then return end -- Animation system handles sprites

    local dx = entity.dir_x or 0
    local dy = entity.dir_y or 0
    local neutral = (dx == 0 and dy == 0)
    local down = (dx == 0 and dy == 1)
    local down_right = (dx == 1 and dy == 1)
    local down_left = (dx == -1 and dy == 1)
    local right = (dx == 1 and dy == 0)
    local up_right = (dx == 1 and dy == -1)
    local up = (dx == 0 and dy == -1)
    local up_left = (dx == -1 and dy == -1)
    local left = (dx == -1 and dy == 0)
    local sprite_index
    local flip = false

    local lookup_type = entity.type == "Enemy" and entity.enemy_type or entity.type
    local config = GameConstants[lookup_type] or GameConstants.Enemy[lookup_type]
    if not config then return end

    if neutral or down then sprite_index = config.sprite_index_offsets.down end
    if right or down_right or up_right then sprite_index = config.sprite_index_offsets.right end
    if up or up_left or down_left then sprite_index = config.sprite_index_offsets.up end
    if left or up_left or down_left then
        sprite_index = config.sprite_index_offsets.right
        flip = true
    end

    entity.base_sprite_index = sprite_index
    entity.sprite_index = sprite_index
    entity.flip_x = flip
    entity.flip_y = false
end

function Rendering.animatable(entity)
    local base = entity.base_sprite_index or entity.sprite_index
    local anim_offset = (flr(t() * 2) % 2)
    entity.sprite_index = base + anim_offset
end

-- Internal sprite drawer (combines flask check and standard drawing)
local function draw_sprite(entity)
    local was_flashing = entity.flash_timer and entity.flash_timer > 0
    Effects.update_flash(entity)

    -- Actual drawing (previously Rendering.drawable)
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

-- Draws all entities matching 'tags'. Optionally sorts them by Y position.
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

function Rendering.sync_shadows(shadow)
    local parent = shadow.parent

    if not parent or not world.msk(parent) then
        world.del(shadow)
        return
    end

    shadow.x = parent.x
    shadow.y = parent.y
    shadow.w = parent.width or 16
    shadow.h = parent.height or 16
    shadow.shadow_offset = parent.shadow_offset or 0
    shadow.shadow_offsets = parent.shadow_offsets
    shadow.shadow_width = parent.shadow_width
    shadow.shadow_height = parent.shadow_height
    shadow.shadow_widths = parent.shadow_widths
    shadow.shadow_heights = parent.shadow_heights
    shadow.direction = parent.direction or parent.current_direction
end

function Rendering.draw_shadow_entity(shadow, clip_square)
    local parent = shadow.parent
    if not parent or not world.msk(parent) then return end

    local dir = parent.direction or parent.current_direction
    local hb = Collision.get_hitbox(parent)

    local sw = shadow.shadow_width
    if shadow.shadow_widths and dir and shadow.shadow_widths[dir] then
        sw = shadow.shadow_widths[dir]
    end
    if not sw then
        local w_scale = 0.8
        if hb.w < 8 then w_scale = 1.0 end
        sw = hb.w * w_scale
    end
    sw = max(8, sw)

    local sh = shadow.shadow_height
    if shadow.shadow_heights and dir and shadow.shadow_heights[dir] then
        sh = shadow.shadow_heights[dir]
    end
    sh = sh or 3

    local offset_y = shadow.shadow_offset or 0
    if shadow.shadow_offsets and dir and shadow.shadow_offsets[dir] then
        offset_y = shadow.shadow_offsets[dir]
    end

    local cx = flr(hb.x + hb.w / 2)
    local ground_y = flr((hb.y + hb.h) - (parent.sprite_offset_y or 0))
    local cy = ground_y + offset_y

    local x1 = cx - flr(sw / 2)
    local x2 = cx + flr(sw / 2)
    local y1 = cy - flr(sh / 2)
    local y2 = cy + flr(sh / 2)

    clip(clip_square.x, clip_square.y, clip_square.w, clip_square.h)
    ovalfill(x1, y1, x2, y2, Rendering.SHADOW_COLOR)
    clip()
end

function Rendering.draw_spotlight(entity, clip_square)
    local center_x = entity.x + (entity.width or 16) / 2
    local center_y = entity.y + (entity.height or 16) / 2
    local radius = entity.spotlight_radius or 48

    clip(clip_square.x, clip_square.y, clip_square.w, clip_square.h)
    circfill(center_x, center_y, radius, Rendering.SPOTLIGHT_COLOR)
    clip()
end

function Rendering.draw_health_bar(entity)
    if not entity.hp then return end

    local shot_cost = entity.shot_cost or 20
    local segments = ceil(entity.max_hp / shot_cost)
    local seg_w = 6
    local bar_h = 3
    local gap = 1
    local total_w = (seg_w + gap) * segments - gap
    local px = flr(entity.x + (entity.width or 16) / 2 - total_w / 2)
    local py = flr(entity.y - 8)

    for i = 0, segments - 1 do
        local start_x = px + i * (seg_w + gap)
        local segment_hp = min(shot_cost, max(0, entity.hp - (i * shot_cost)))

        if segment_hp >= shot_cost then
            rectfill(start_x, py, start_x + seg_w - 1, py + bar_h, 11)
        elseif segment_hp > 0 then
            rectfill(start_x, py, start_x + seg_w - 1, py + bar_h, 8)
            local fill_w = ceil((segment_hp / shot_cost) * seg_w)
            rectfill(start_x, py, start_x + fill_w - 1, py + bar_h, 9)
        else
            rectfill(start_x, py, start_x + seg_w - 1, py + bar_h, 8)
        end
    end
end

function Rendering.draw_hitbox(entity)
    local hb = Collision.get_hitbox(entity)
    rect(hb.x, hb.y, hb.x + hb.w, hb.y + hb.h, 8)
end

function Rendering.palette_swappable(entity)
    if not entity.palette_swaps then return end

    for _, swap in ipairs(entity.palette_swaps) do
        pal(swap.from, swap.to)
    end
end

return Rendering
