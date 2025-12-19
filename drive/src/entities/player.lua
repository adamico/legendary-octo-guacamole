local player = {
   x = GameConstants.Player.starting_position.x,
   y = GameConstants.Player.starting_position.y,

   width = 20,
   height = 32,
   sprite_index_offset = GameConstants.Player.sprite_index_offset,
   animation_start = 0,
   animation_end = 1,
   animation_frame_rate = 30,
   sprite = 0,
   score = 0,
}

return world.ent("drawable,animatable,player", player)