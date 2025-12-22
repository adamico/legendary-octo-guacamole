-- Rendering and visual effects systems
local GameConstants = require("constants")
local Collision = require("collision")
local qsort = require("qsort")

local Rendering = {}

-- Spotlight color constants
Rendering.SPOTLIGHT_COLOR = 33
Rendering.SHADOW_COLOR = 32

local spotlight_initialized = false

-- Initialize the extended palette (colors 32-63)
-- Defines lighter/darker variants for base colors 0-15
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

-- Initialize the spotlight color table
function Rendering.init_spotlight()
    if spotlight_initialized then return end
    Rendering.reset_spotlight()
    spotlight_initialized = true
end

-- Reset the spotlight color table (can be called each frame after palette changes)
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
-- Skip entities with FSM - they use the animation system
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

    -- Get sprite config (use enemy_type for enemies, type for everything else)
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
    entity.sprite_index = sprite_index -- Also set directly for non-animated entities
    entity.flip_x = flip
    entity.flip_y = false
end

-- Simple animation system: alternates between base sprite and base+1 every 30 frames
function Rendering.animatable(entity)
    local base = entity.base_sprite_index or entity.sprite_index
    local anim_offset = (flr(t() * 2) % 2) -- 0 or 1, switches every 0.5s (30 frames)
    entity.sprite_index = base + anim_offset
end

-- Drawable system: render entity sprite
-- Supports composite sprites where top and bottom halves are drawn separately
-- Supports sprite_offset_x/y for visual adjustments (elevation, etc.)
function Rendering.drawable(entity)
    local flip_x = entity.flip_x or entity.flip or false
    local flip_y = entity.flip_y or false
    local sx = entity.x + (entity.sprite_offset_x or 0)
    local sy = entity.y + (entity.sprite_offset_y or 0)

    -- Check for composite sprite (top + bottom halves)
    if entity.sprite_top ~= nil and entity.sprite_bottom ~= nil then
        -- Picotron sspr: sspr(sprite_index, sx, sy, sw, sh, dx, dy, dw, dh, flip_x, flip_y)
        -- sx, sy are coordinates WITHIN the sprite (not the spritesheet)

        -- Use dynamic split_row (defaults to height/2)
        local width = entity.width or 16
        local height = entity.height or 16
        local split_row = entity.split_row or flr(height / 2)
        local bottom_height = height - split_row

        -- Draw top half (first split_row rows of top sprite)
        sspr(
            entity.sprite_top, -- sprite index
            0, 0,              -- source x, y within sprite
            width, split_row,  -- source width, height (top portion)
            sx, sy,            -- destination
            width, split_row,  -- destination width, height
            flip_x, flip_y
        )
        -- Draw bottom half (remaining rows of bottom sprite)
        sspr(
            entity.sprite_bottom, -- sprite index
            0, split_row,         -- source x, y within sprite (start at split_row)
            width, bottom_height, -- source width, height (bottom portion)
            sx, sy + split_row,   -- destination (offset by split_row)
            width, bottom_height,
            flip_x, flip_y
        )
    else
        -- Standard single sprite
        spr(entity.sprite_index, sx, sy, flip_x, flip_y)
    end
end

-- Shadow System: Sync shadow entity position to parent
function Rendering.sync_shadows(shadow)
    local parent = shadow.parent

    -- Cleanup if parent is gone
    if not parent or not world.msk(parent) then
        world.del(shadow)
        return
    end

    -- Sync base position (ground footprint)
    shadow.x = parent.x
    shadow.y = parent.y

    -- Sync visual/centering properties
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

    -- Current orientation
    local dir = parent.direction or parent.current_direction
    local hb = Collision.get_hitbox(parent)

    -- Determine width/height
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

    -- Vertical offset override
    local offset_y = shadow.shadow_offset or 0
    if shadow.shadow_offsets and dir and shadow.shadow_offsets[dir] then
        offset_y = shadow.shadow_offsets[dir]
    end

    -- UNIFIED ALIGNMENT:
    -- 1. Center horizontally on the HITBOX (physical center)
    -- 2. Anchor vertically to the HITBOX bottom minus visual elevation (physical footprint)
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

-- Spotlight system
function Rendering.draw_spotlight(entity, clip_square)
    local center_x = entity.x + (entity.width or 16) / 2
    local center_y = entity.y + (entity.height or 16) / 2
    local radius = entity.spotlight_radius or 48

    clip(clip_square.x, clip_square.y, clip_square.w, clip_square.h)
    circfill(center_x, center_y, radius, Rendering.SPOTLIGHT_COLOR)
    clip()
end

-- Health bar system: three-state visualization
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
            -- Full segment: GREEN (shot ready)
            rectfill(start_x, py, start_x + seg_w - 1, py + bar_h, 11)
        elseif segment_hp > 0 then
            -- Partial segment: RED background + ORANGE fill (charging)
            rectfill(start_x, py, start_x + seg_w - 1, py + bar_h, 8)
            local fill_w = ceil((segment_hp / shot_cost) * seg_w)
            rectfill(start_x, py, start_x + fill_w - 1, py + bar_h, 9)
        else
            -- Empty segment: RED only (no ammo)
            rectfill(start_x, py, start_x + seg_w - 1, py + bar_h, 8)
        end
    end
end

-- Debug hitboxes
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

-- Y-Sorted Rendering: Gathers, sorts, and draws entities
function Rendering.draw_ysorted(world, tags, draw_fn)
    local entities = {}
    world.sys(tags, function(e)
        add(entities, e)
    end)()

    -- Sort by Y position (bottom of sprite)
    -- Using entity.y + entity.height for sorting baseline
    qsort(entities, function(a, b)
        local ay = a.y + (a.height or 16)
        local by = b.y + (b.height or 16)
        return ay < by
    end)

    for i = 1, #entities do
        draw_fn(entities[i])
    end
end

return Rendering
