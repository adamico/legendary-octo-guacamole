-- Shadow entity factory
local Shadow = {}

function Shadow.spawn(world, parent)
    local shadow = {
        type = "Shadow",
        parent = parent,
        x = parent.x,
        y = parent.y,
        w = parent.width or 16,
        h = parent.height or 16,
        -- Initial properties copied from parent
        shadow_offset_y = parent.shadow_offset_y or 0,
        shadow_offsets = parent.shadow_offsets,
        shadow_width = parent.shadow_width,
        shadow_height = parent.shadow_height,
        shadow_widths = parent.shadow_widths,
        shadow_heights = parent.shadow_heights,
    }

    local ent = world.ent("shadow_entity,drawable_shadow", shadow)
    parent.shadow_entity = ent
    return ent
end

return Shadow
