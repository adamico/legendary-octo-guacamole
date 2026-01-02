-- Emotions system: displays visual indicators above enemies based on AI state
-- Refactored to use pure picobloc ECS queries (no EntityProxy)
local GameConstants = require("src/game/game_config")
local TextUtils = require("src/utils/text_utils")

local Emotions = {}

--- Set an emotion on an entity using direct buffer access
--- @param emotion_state table - The emotion_state component buffer
--- @param i integer - The entity index in the archetype
--- @param emotion_type string - "alert", "confused", or "idle"
function Emotions.set_at(emotion_state, i, emotion_type)
    local config = GameConstants.Emotions[emotion_type]
    if not config then return end

    emotion_state.emotion[i] = emotion_type
    emotion_state.emotion_timer[i] = config.duration
    emotion_state.emotion_phase[i] = rnd(1) -- Random phase for bounce offset
end

--- Clear any active emotion on entity using direct buffer access
--- @param emotion_state table - The emotion_state component buffer
--- @param i integer - The entity index in the archetype
function Emotions.clear_at(emotion_state, i)
    emotion_state.emotion[i] = nil
    emotion_state.emotion_timer[i] = 0
    emotion_state.emotion_phase[i] = 0
end

-- ============================================================================
-- Backwards-compatible API for EntityProxy callers (AI modules, etc.)
-- These will be deprecated once all AI is migrated to pure ECS
-- ============================================================================

--- Set an emotion on an entity (legacy EntityProxy API)
--- @param entity EntityProxy - The entity proxy
--- @param emotion_type string - "alert", "confused", "idle", etc.
function Emotions.set(entity, emotion_type)
    local config = GameConstants.Emotions[emotion_type]
    if not config then return end

    -- Write directly through proxy (uses __newindex metamethod)
    -- Note: This still works because we added emotion_state component mapping
    -- to EntityProxy won't work without updating entity_proxy.lua
    -- For now, use query_entity approach:
    local world = entity._world
    local id = entity._id
    world:query_entity(id, {"emotion_state"}, function(_, emotion_state)
        emotion_state.emotion[0] = emotion_type
        emotion_state.emotion_timer[0] = config.duration
        emotion_state.emotion_phase[0] = rnd(1)
    end)
end

--- Clear any active emotion on entity (legacy EntityProxy API)
--- @param entity EntityProxy - The entity proxy
function Emotions.clear(entity)
    local world = entity._world
    local id = entity._id
    world:query_entity(id, {"emotion_state"}, function(_, emotion_state)
        emotion_state.emotion[0] = nil
        emotion_state.emotion_timer[0] = 0
        emotion_state.emotion_phase[0] = 0
    end)
end

--- Update emotion timers (call once per frame for all entities)
--- Uses pure picobloc query, no EntityProxy
function Emotions.update(world)
    world:query({"emotional", "emotion_state"}, function(ids, _, emotion_state)
        for i = ids.first, ids.last do
            local timer = emotion_state.emotion_timer[i]
            if timer and timer > 0 then
                emotion_state.emotion_timer[i] = timer - 1
                if emotion_state.emotion_timer[i] <= 0 then
                    Emotions.clear_at(emotion_state, i)
                end
            end
        end
    end)
end

--- Draw emotion indicators above entities using print with p8scii controls
--- Uses pure picobloc query, no EntityProxy
function Emotions.draw(world)
    local emotions_config = GameConstants.Emotions
    local offset_y = emotions_config.offset_y or -10
    local bounce_speed = emotions_config.bounce_speed or 0.15
    local bounce_height = emotions_config.bounce_height or 2
    local outline_col = emotions_config.outline_color or 0

    world:query({"emotional", "emotion_state", "position", "size?"}, function(ids, _, emotion_state, pos, size)
        for i = ids.first, ids.last do
            local emotion = emotion_state.emotion[i]
            if emotion then
                local config = emotions_config[emotion]
                if config then
                    -- Calculate position above entity center
                    local w = size and size.width[i] or 16
                    local cx = pos.x[i] + w / 2 - 2
                    local cy = pos.y[i] + offset_y

                    -- Add bounce animation
                    local phase = emotion_state.emotion_phase[i] or 0
                    local bounce = sin((t() * bounce_speed + phase) * 2 * 3.14159) * bounce_height

                    -- Draw the emotion text with outline
                    local final_cy = cy + bounce
                    TextUtils.print_outlined(config.text, cx, final_cy, config.color, outline_col)
                end
            end
        end
    end)
end

return Emotions
