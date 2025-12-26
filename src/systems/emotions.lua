-- Emotions system: displays visual indicators above enemies based on AI state
local GameConstants = require("src/constants")

local Emotions = {}

-- Set an emotion on an entity
-- @param entity: the entity to set the emotion on
-- @param emotion_type: "alert", "confused", or "idle"
function Emotions.set(entity, emotion_type)
    local config = GameConstants.Emotions[emotion_type]
    if not config then return end

    entity.emotion = emotion_type
    entity.emotion_timer = config.duration
    entity.emotion_phase = rnd(1) -- Random phase for bounce offset
end

-- Clear any active emotion on entity
function Emotions.clear(entity)
    entity.emotion = nil
    entity.emotion_timer = nil
    entity.emotion_phase = nil
end

-- Update emotion timers (call once per frame for all entities)
function Emotions.update(world)
    world.sys("enemy", function(entity)
        if entity.emotion_timer then
            entity.emotion_timer = entity.emotion_timer - 1
            if entity.emotion_timer <= 0 then
                Emotions.clear(entity)
            end
        end
    end)()
end

-- Draw emotion indicators above entities using print with p8scii controls
function Emotions.draw(world)
    local emotions_config = GameConstants.Emotions
    local offset_y = emotions_config.offset_y or -10
    local bounce_speed = emotions_config.bounce_speed or 0.15
    local bounce_height = emotions_config.bounce_height or 2
    local outline_col = emotions_config.outline_color or 0

    world.sys("enemy", function(entity)
        if not entity.emotion then return end

        local config = emotions_config[entity.emotion]
        if not config then return end

        -- Calculate position above entity center
        local cx = entity.x + (entity.width or 16) / 2 - 2
        local cy = entity.y + offset_y

        -- Add bounce animation
        local phase = entity.emotion_phase or 0
        local bounce = sin((t() * bounce_speed + phase) * 2 * 3.14159) * bounce_height
        cy = cy + bounce

        -- Build p8scii string with outline for visibility
        -- Format: \^o{outline_color}{neighbor_bits}{text}
        -- ff = all 8 neighbors for full outline
        local outline_hex = string.format("%x", outline_col)
        local text_str = string.format("\^o%sff%s", outline_hex, config.text)

        -- Draw the emotion text with outline
        print(text_str, cx, cy, config.color)
    end)()
end

return Emotions
