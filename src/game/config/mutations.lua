-- Mutations configuration

return {
   Mutation = {
      Mutation = {
         entity_type = "Mutation",
         tags = "mutation,velocity,collidable,drawable,sprite,background,shadow",
         pickup_effect = "health",
         width = 16,
         height = 16,
         hitbox_from_projectile = true,
         sprite_index_offsets = {
            down = 36,
            right = 36,
            left = 36,
            up = 36,
         },
         sprite_offset_y = 6,
         shadow_offset_y = 4,
         shadow_width = 6,
      },
   }
}
