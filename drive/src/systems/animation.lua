local machine = require("lua-state-machine/statemachine")
local GameConstants = require("constants")

local Animation = {}

-- Default animation timing (frames count and speed in ticks per frame)
Animation.DEFAULT_ANIM_PARAMS = {
    idle = {frames = 2, speed = 30},
    walking = {frames = 2, speed = 8},
    attacking = {frames = 4, speed = 6},
    hurt = {frames = 2, speed = 4},
    death = {frames = 4, speed = 8}
}

-- Get the direction name from entity dir_x/dir_y
local function get_direction(entity)
    local dx = entity.dir_x or 0
    local dy = entity.dir_y or 0

    -- Priority: horizontal over vertical for diagonals
    if dx > 0 then return "right" end
    if dx < 0 then return "left" end
    if dy > 0 then return "down" end
    if dy < 0 then return "up" end

    -- Default to down if no direction
    return "down"
end

-- Get animation config for entity type
local function get_entity_config(entity)
    if entity.type == "Enemy" and entity.enemy_type then
        return GameConstants.Enemy[entity.enemy_type]
    end
    return GameConstants[entity.type]
end

function Animation.init_fsm(entity)
    entity.fsm = machine.create({
        initial = "idle",
        events = {
            {name = "walk",    from = "idle",                           to = "walking"},
            {name = "stop",    from = "walking",                        to = "idle"},
            {name = "attack",  from = {"idle", "walking"},              to = "attacking"},
            {name = "hit",     from = {"idle", "walking", "attacking"}, to = "hurt"},
            {name = "die",     from = "*",                              to = "death"},
            {name = "recover", from = "hurt",                           to = "idle"},
            {name = "finish",  from = "attacking",                      to = "idle"}
        },
        callbacks = {
            onenterstate = function(self, event, from, to)
                entity.anim_timer = 0
            end
        }
    })
    entity.anim_timer = 0
    entity.current_direction = "down"
end

function Animation.update_fsm(entity)
    if not entity.fsm then
        Animation.init_fsm(entity)
    end

    local fsm = entity.fsm

    -- Can't transition out of death
    if fsm:is("death") then return end

    -- Update current direction for animation lookup
    entity.current_direction = get_direction(entity)

    -- Handle movement states
    local is_moving = (abs(entity.vel_x or 0) > 0.1 or abs(entity.vel_y or 0) > 0.1)

    if fsm:is("idle") then
        if is_moving then fsm:walk() end
    elseif fsm:is("walking") then
        if not is_moving then fsm:stop() end
    end

    -- Hit transition
    if entity.invuln_timer and entity.invuln_timer > 0 and not fsm:is("hurt") then
        if fsm:can("hit") then fsm:hit() end
    end

    -- Recover from hurt
    if fsm:is("hurt") and (entity.invuln_timer or 0) <= 0 then
        if fsm:can("recover") then fsm:recover() end
    end

    -- Death check (backup)
    if entity.hp and entity.hp <= 0 and not fsm:is("death") then
        if fsm:can("die") then fsm:die() end
    end
end

function Animation.animate(entity)
    if not entity.fsm then return end

    entity.anim_timer = (entity.anim_timer or 0) + 1

    local state = entity.fsm.current
    local direction = entity.current_direction or "down"
    local config = get_entity_config(entity)

    -- Get animation parameters
    local anim_params = Animation.DEFAULT_ANIM_PARAMS[state]
    if not anim_params then return end

    local frames = anim_params.frames
    local speed = anim_params.speed

    -- Override with entity-specific config if available
    if config and config.animations then
        local dir_anims = config.animations[direction]
        if dir_anims and dir_anims[state] then
            -- Per-direction, per-state config: { base = X, frames = Y, speed = Z }
            local state_anim = dir_anims[state]
            frames = state_anim.frames or frames
            speed = state_anim.speed or speed
        elseif config.animations[state] then
            -- Flat structure fallback: { offset = X, frames = Y, speed = Z }
            local state_anim = config.animations[state]
            frames = state_anim.frames or frames
            speed = state_anim.speed or speed
        end
    end

    -- Calculate current frame
    local frame = 0
    if state == "death" then
        frame = min(flr(entity.anim_timer / speed), frames - 1)

        -- When death animation completes, trigger cleanup
        if entity.anim_timer >= frames * speed then
            local Combat = require("combat")
            local handler = Combat.DeathHandlers[entity.type] or Combat.DeathHandlers.default
            if not entity.death_cleanup_called then
                entity.death_cleanup_called = true
                handler(entity)
            end
        end
    elseif state == "attacking" then
        frame = flr(entity.anim_timer / speed) % frames
        if entity.anim_timer >= frames * speed then
            entity.fsm:finish()
        end
    else
        frame = flr(entity.anim_timer / speed) % frames
    end

    -- Determine base sprite index
    local base_sprite = 0

    if config and config.animations then
        local dir_anims = config.animations[direction]
        if dir_anims and dir_anims[state] and dir_anims[state].base then
            -- Per-direction, per-state base sprite
            base_sprite = dir_anims[state].base
        elseif config.sprite_index_offsets and config.sprite_index_offsets[direction] then
            -- Use direction offset + state offset (old flat structure)
            base_sprite = config.sprite_index_offsets[direction]
            if config.animations[state] and config.animations[state].offset then
                base_sprite = base_sprite + config.animations[state].offset
            end
        end
    elseif config and config.sprite_index_offsets then
        -- Fallback: just use direction offset
        base_sprite = config.sprite_index_offsets[direction] or 0
    end

    -- Apply flip from animation config or fallback to left direction check
    entity.flip = false
    if config and config.animations then
        local dir_anims = config.animations[direction]
        if dir_anims and dir_anims[state] and dir_anims[state].flip then
            entity.flip = true
        end
    end

    entity.sprite_index = base_sprite + frame
end

return Animation
