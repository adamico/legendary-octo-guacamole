-- Obstacles configurations: Rock, Destructible, Chest, LockedChest, ShopItem

return {
   Obstacle = {
      Rock = {
         entity_type = "Rock",
         obstacle = true,
         tags = "obstacle,collidable,drawable,sprite,world_obj,middleground,static",
         width = 16,
         height = 16,
         hitbox_width = 16,
         hitbox_height = 16,
         hitbox_offset_x = 4,
         hitbox_offset_y = 4,
         outline_color = nil,
      },
      Destructible = {
         entity_type = "Destructible",
         obstacle = true,
         destructible = true,
         tags = "obstacle,collidable,drawable,sprite,world_obj,destructible,middleground,static",
         hp = 1,
         width = 16,
         height = 16,
         hitbox_width = 16,
         hitbox_height = 16,
         hitbox_offset_x = 4,
         hitbox_offset_y = 4,
         outline_color = nil,
      },
      Chest = {
         entity_type = "Chest",
         obstacle = true,
         is_chest = true,
         tags = "obstacle,collidable,drawable,sprite,world_obj,chest,middleground,static",
         hp = 1,
         width = 16,
         height = 16,
         hitbox_width = 16,
         hitbox_height = 16,
         hitbox_offset_x = 0,
         hitbox_offset_y = 0,
         outline_color = nil,
         sprite_index = 166, -- Normal chest sprite
         sprite_open = 168,  -- Open chest sprite (if you have one, otherwise nil)
         loot_min = 1,       -- Minimum pickup drops
         loot_max = 3,       -- Maximum pickup drops
      },
      LockedChest = {
         entity_type = "LockedChest",
         obstacle = true,
         is_chest = true,
         is_locked = true,
         tags = "obstacle,collidable,drawable,sprite,world_obj,chest,locked,middleground,static",
         hp = 1,
         width = 16,
         height = 16,
         hitbox_width = 16,
         hitbox_height = 16,
         hitbox_offset_x = 0,
         hitbox_offset_y = 0,
         outline_color = nil,
         sprite_index = 167, -- Locked chest sprite
         sprite_open = 168,  -- Open chest sprite (if you have one, otherwise nil)
         loot_min = 2,       -- Minimum pickup drops
         loot_max = 6,       -- Maximum pickup drops
         key_cost = 1,       -- Keys required to open
      },
      ShopItem = {
         entity_type = "ShopItem",
         obstacle = true,
         is_shop_item = true,
         tags = "obstacle,collidable,drawable,sprite,world_obj,shop_item,middleground,static",
         width = 16,
         height = 16,
         hitbox_width = 12,
         hitbox_height = 10,
         hitbox_offset_x = 2,
         hitbox_offset_y = 6,
         sprite_index = 58, -- Pedestal sprite (item sprite set at spawn)
         outline_color = nil,
         -- Item properties set at spawn time: item_id, price, apply_fn, item_name, item_sprite
      },
   },
}
