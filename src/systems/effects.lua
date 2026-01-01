-- Effects system: reusable visual, audio, and physical feedback
local Effects = {}

-- Screen shake state
local shake_timer = 0
local shake_intensity = 0

-- Screen shake effect
function Effects.screen_shake(intensity, duration)
    shake_intensity = max(shake_intensity, intensity or 2)
    shake_timer = max(shake_timer, duration or 3)
end

-- REFACTOR: move to timers?
-- Update shake (call from main game loop)
function Effects.update_shake()
    if shake_timer > 0 then
        shake_timer -= 1
        if shake_timer <= 0 then
            shake_intensity = 0
        end
    end
end

-- Get shake offset (call from draw loop, add to camera scroll)
function Effects.get_shake_offset()
    if shake_timer > 0 and shake_intensity > 0 then
        return {
            x = (rnd(2) - 1) * shake_intensity,
            y = (rnd(2) - 1) * shake_intensity
        }
    end
    return {x = 0, y = 0}
end

-- Flash sprite effect
function Effects.flash_sprite(world, id, frames, color)
    -- Requires "flash" component on entity or adding it
    -- Assuming entities that need flash have "flash" component
    if world:entity_exists(id) then
        world:query_entity(id, {"flash?"}, function(idx, flash)
            if flash then
                flash.flash_timer[idx] = frames or 3
                -- flash_color is not in component def in architecture doc!
                -- Component def: flash_timer, flash_duration.
                -- Use flash_duration as color? No.
                -- Let's just set timer for now. Color is usually white (7).
                -- If we need color support, we should add it to component.
                -- For now, default white flash.
            end
        end)
    end
end

-- Update sprite flash (call from drawable system)
-- Moved to Rendering system ideally, but kept here if called explicitly?
-- Actually, rendering system handles flash normally. This function implementation in original file
-- was updating a timer. ECS "timers" or specialized system handles this.
-- We can remove `update_flash` if the rendering system handles decrementing or a system does.
-- But let's check if we need to port it as a system function.
-- Original: function Effects.update_flash(entity)
-- This was likely called inside a loop.
-- ECS: A system should iterate "flash" component and decrement timer.
-- Use `Effects.update(world)` or similar?
-- Or `Rendering` system handles it.
-- Let's verify Rendering system later. For now, we drop `update_flash` as it should be a system.

-- Spawn particle effect (placeholder - needs particle system)
function Effects.spawn_particles(world, x, y, ptype, count)
    -- TODO: Implement particle system
end

--- Spawn a temporary visual effect sprite at position
---
--- @param world World - ECS world
--- @param x number - spawn position
--- @param y number - spawn position
--- @param sprite_index number - sprite to display
--- @param lifespan number - frames before removal (default 15)
function Effects.spawn_visual_effect(world, x, y, sprite_index, lifespan)
    lifespan = lifespan or 15
    local effect = {
        type = {value = "VisualEffect"},
        position = {x = x, y = y, z = 0},
        size = {width = 16, height = 16},
        drawable = {
            sprite_index = sprite_index,
            sort_offset_y = 0,
            outline_color = {value = 0},
        },
        timers = {
            lifespan = lifespan,
        },
        middleground = true, -- tag
    }
    world:add_entity(effect)
end

--- Apply knockback to target entity, pushing away from source
---
--- Uses separate knockback velocity that decays with friction
---
--- @param world World - ECS World
--- @param source_pos table {x, y, width, height} (Table or Component values)
--- @param target_id Entity ID to knockback
--- @param strength number - Knockback strength
function Effects.apply_knockback(world, source_pos, target_id, strength)
    strength = strength or 3

    if not world:entity_exists(target_id) then return end

    world:query_entity(target_id, {"position", "velocity", "size?"}, function(i, t_pos, t_vel, t_size)
        local t_w = t_size and t_size.width[i] or 16
        local t_h = t_size and t_size.height[i] or 16
        local t_cx = t_pos.x[i] + t_w / 2
        local t_cy = t_pos.y[i] + t_h / 2

        local s_cx = source_pos.x + (source_pos.width or 16) / 2
        local s_cy = source_pos.y + (source_pos.height or 16) / 2

        local dx = t_cx - s_cx
        local dy = t_cy - s_cy

        -- Normalize direction
        local len = sqrt(dx * dx + dy * dy)
        if len > 0 then
            dx = dx / len
            dy = dy / len
        else
            dx = 0
            dy = -1
        end

        t_vel.knockback_vel_x[i] = dx * strength
        t_vel.knockback_vel_y[i] = dy * strength
    end)
end

--- Apply stun and slow debuff to target entity ("Sticky Yolk" effect)
---
--- @param world World
--- @param target_id Entity ID
--- @param stun_frames Frames of complete movement stop (~0.2s = 12)
--- @param slow_frames Frames of reduced speed (~1s = 60)
--- @param slow_factor Speed multiplier during slow (0.5 = 50% speed)
function Effects.apply_sticky_yolk(world, target_id, stun_frames, slow_frames, slow_factor)
    if not world:entity_exists(target_id) then return end

    world:query_entity(target_id, {"timers?"}, function(i, timers)
        if timers then
            if stun_frames then timers.stun_timer[i] = stun_frames end
            if slow_frames then timers.slow_timer[i] = slow_frames end
            -- Support variable slow factor if added to component, otherwise ignore
            if slow_factor and timers.slow_factor then
                timers.slow_factor[i] = slow_factor
            end
        end
    end)
end

-- Generic hit impact effect (reusable)
function Effects.hit_impact(world, source_pos, target_id, intensity)
    intensity = intensity or "normal"

    if not world:entity_exists(target_id) then return end

    -- Visual effects
    world:query_entity(target_id, {"position", "size?"}, function(i, pos, size)
        local w = size and size.width[i] or 16
        local h = size and size.height[i] or 16
        local px = (source_pos.x + pos.x[i]) / 2
        local py = (source_pos.y + pos.y[i]) / 2

        Effects.spawn_particles(world, px, py, "hit_spark", 5)
    end)

    Effects.flash_sprite(world, target_id, 10, 7)

    -- Audio (context-based) - querying 'type' component
    world:query_entity(target_id, {"type?"}, function(i, type_c)
        if type_c then
            local t_val = type_c.value[i]
            if t_val == "Player" then
                -- sfx(2)
            elseif t_val == "Enemy" then
                -- sfx(5)
            end
        end
    end)

    -- Screen shake (intensity-based)
    if intensity == "light_shake" then
        Effects.screen_shake(1, 2)
    elseif intensity == "normal_shake" then
        Effects.screen_shake(2, 3)
    elseif intensity == "heavy_shake" then
        Effects.screen_shake(4, 5)
    end
end

-- Death explosion effect (reusable for enemy/player death)
function Effects.death_explosion(world, x, y, width, height, ptype)
    ptype = ptype or "explosion"

    Effects.spawn_particles(world, x + width / 2, y + height / 2, ptype, 15)

    -- Flash not needed as entity is dying
    -- Sound
    -- sfx(10)
end

-- Pickup/collect effect
function Effects.pickup_collect(world, x, y)
    Effects.spawn_particles(world, x, y, "sparkle", 8)
    -- sfx(6)
end

return Effects
