-- Entity lifecycle management: FSM initialization and state transitions
local machine = require("lib/lua-state-machine/statemachine")
local DeathHandlers = require("src/lifecycle/death_handlers")

local Lifecycle = {}

-- Initialize FSM for an entity
function Lifecycle.init_fsm(entity)
    local function reset_timer()
        entity.anim_timer = 0
    end

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
            onenteridle = reset_timer,
            onenterwalking = reset_timer,
            onenterattacking = reset_timer,
            onenterhurt = reset_timer,
            onenterdeath = function()
                reset_timer()
                -- Deactivate active processing tags on death
                local tags_to_remove = "controllable,collidable,shooter,player,enemy,acceleration,velocity,health"
                world.unt(entity, tags_to_remove)

                -- Stop remaining movement
                entity.vel_x = 0
                entity.vel_y = 0
                -- REFACTOR: Use SoundManager.play("enemy_death") or similar
                sfx(8) -- enemy death sound
            end
        }
    })
    entity.anim_timer = 0
    entity.current_direction = entity.direction or entity.current_direction or "down"
end

-- Update entity FSM based on game state
function Lifecycle.update_fsm(entity, world)
    if not entity.fsm then
        Lifecycle.init_fsm(entity)
    end

    local fsm = entity.fsm

    -- Handle completed animations (Death / Attack finish)
    if entity.anim_complete_state then
        if entity.anim_complete_state == "death" then
            -- Priority: enemy_type (for specific enemies like Boss), then type, then default
            local handler = DeathHandlers[entity.enemy_type]
                         or DeathHandlers[entity.type]
                         or DeathHandlers.default
            if not entity.death_cleanup_called then
                entity.death_cleanup_called = true
                -- Pass world if available, checking for both local arg and global fallback
                handler(world or _G.world, entity)
            end
        elseif entity.anim_complete_state == "attacking" then
            if not entity.anim_looping and fsm.finish then
                fsm:finish()
            end
        end
    end

    -- Can't transition out of death
    if fsm:is("death") then return end

    -- Handle movement transitions
    local is_moving = (abs(entity.vel_x or 0) > 0.1 or abs(entity.vel_y or 0) > 0.1)

    if is_moving then
        if fsm.walk then fsm:walk() end
    else
        if fsm.stop then fsm:stop() end
    end

    -- Hit transition (invuln timer indicates recent damage)
    if entity.invuln_timer and entity.invuln_timer > 0 then
        if fsm.hit then fsm:hit() end
    elseif fsm:is("hurt") then
        if fsm.recover then fsm:recover() end
    end

    -- Death check
    if entity.hp and entity.hp <= 0 then
        if not fsm:is("death") then
            fsm:die()
        end
    end
end

return Lifecycle
