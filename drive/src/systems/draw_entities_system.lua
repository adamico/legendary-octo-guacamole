return world.sys("drawable", function(entity)
   if entity.sprite then spr(entity.sprite + entity.sprite_index_offset, entity.x, entity.y) end
   rrect(entity.x, entity.y, entity.width, entity.height, 0, entity.color or 8)
end)