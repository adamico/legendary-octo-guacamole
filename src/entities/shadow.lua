-- Shadow entity factory
local Shadow = {}

function Shadow.spawn(world, parent)
    local shadow = {
        type = "Shadow",
        parent = parent,
        x = parent.x,
        y = parent.y,
        w = parent.width or 16,
        h = parent.height or 8,
        -- Initial properties copied from parent
        shadow_offset_y = parent.shadow_offset_y or 0,
        shadow_offset_x = parent.shadow_offset_x or 0,
        shadow_offsets_y = parent.shadow_offsets_y,
        shadow_offsets_x = parent.shadow_offsets_x,
        shadow_width = parent.shadow_width,
        shadow_height = parent.shadow_height,
        shadow_widths = parent.shadow_widths,
        shadow_heights = parent.shadow_heights,
    }

    local tags = "shadow_sync,drawable_shadow,background"
    local ent = world.ent(tags, shadow)
    parent.shadow_entity = ent
    return ent
end

return Shadow
