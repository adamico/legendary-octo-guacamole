-- Effects configurations: PlacedBomb, Explosion, Emotions, FloatingText

return {
   -- Placed bomb entity (not the pickup)
   PlacedBomb = {
      entity_type = "PlacedBomb",
      tags = "bomb,drawable,sprite,timers,shadow,middleground",
      width = 16,
      height = 16,
      sprite_index = 38, -- Bomb placed sprite
      sprite_index_offsets = {
         down = 38,
         up = 38,
         left = 38,
         right = 38,
      },
      fuse_time = 180,      -- 3 seconds at 60fps
      explosion_radius = 1, -- 1 tile = 3x3 grid centered on bomb
      shadow_offset_y = 3,
      shadow_width = 12,
   },
   -- Explosion effect entity (reusable for bombs, enemy attacks, etc.)
   Explosion = {
      entity_type = "Explosion",
      tags = "explosion,collidable,drawable,sprite,timers,middleground",
      width = 16,
      height = 16,
      sprite_index = 44,
      sprite_index_offsets = {
         down = 44,
         up = 44,
         left = 44,
         right = 44,
      },
      hitbox_width = 14,
      hitbox_height = 14,
      hitbox_offset_x = 1,
      hitbox_offset_y = 1,
      lifespan = 30,
   },
   Emotions = {
      alert = {text = "!", color = 8, duration = 60}, -- red "!" when spotting player
      confused = {text = "?", color = 12, duration = 90}, -- cyan "?" when losing player
      idle = {text = "♪", color = 11, duration = 120}, -- green "♪" when wandering
      stunned = {text = "★", color = 10, duration = 90}, -- yellow "★" when stunned
      following = {text = "@", color = 14, duration = 60}, -- pink/flesh "@" when following
      chasing = {text = "🐱", color = 8, duration = 60}, -- red "cat" when chasing enemy
      seeking_food = {text = "😐", color = 13, duration = 60}, -- indigo/blue "neutral" when hungry
      offset_y = -18, -- Vertical offset above entity
      bounce_speed = 0.15, -- Bounce animation speed
      bounce_height = 2, -- Bounce amplitude in pixels
      outline_color = 0, -- Black outline for visibility
   },
   FloatingText = {
      rise_speed = 0.5,   -- Pixels per frame to rise
      duration = 45,      -- Total frames before removal
      fade_duration = 15, -- Frames for fade out
      damage_color = 8,   -- Red for damage
      heal_color = 11,    -- Green for healing
      pickup_color = 10,  -- Yellow for pickups
      outline_color = 0,  -- Black outline for visibility
      offset_y = -8,      -- Initial vertical offset from entity top
      spread = 8,         -- Horizontal spread for multiple texts
   },
}
