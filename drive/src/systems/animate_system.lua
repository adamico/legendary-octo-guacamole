return world.sys("animatable", function(entity)
   entity.animation_timer = (entity.animation_timer or 0) + 1
   if entity.animation_timer < entity.animation_frame_rate then return end
   entity.animation_timer = 0
   entity.sprite += 1
   if entity.sprite > entity.animation_end then
      entity.sprite = entity.animation_start
   end
end)