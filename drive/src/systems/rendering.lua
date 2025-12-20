-- Rendering and visual effects systems
local GameConstants = require("constants")

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
    spotlight_initialized = true
end

-- Sprite system: update sprite based on direction
function Rendering.change_sprite(entity)
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

    entity.sprite_index = sprite_index
    entity.flip = flip
end

-- Simple animation system
function Rendering.animatable(entity)
    entity.sprite_index = t() * 30 % 30 < 15 and entity.sprite_index or entity.sprite_index + 1
end

-- Drawable system: render entity sprite
function Rendering.drawable(entity)
    spr(entity.sprite_index, entity.x, entity.y, entity.flip)
end

-- Shadow system
function Rendering.draw_shadow(entity, clip_square)
    local x1, y1 = entity.x + 1, entity.y + 11
    local x2, y2 = entity.x + entity.width - 2, y1 + 6
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

return Rendering
