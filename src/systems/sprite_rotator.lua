local Rotator = {}

Rotator.cache = {}

-- Get a rotated version of the sprite (Userdata)
-- angle must be 0, 90, 180, or 270
function Rotator.get(sprite_index, angle)
   -- Normalize angle to 0, 90, 180, 270
   local normalized_angle = angle % 360

   if normalized_angle == 0 then
      return sprite_index
   end

   if not Rotator.cache[sprite_index] then
      Rotator.cache[sprite_index] = {}
   end

   if Rotator.cache[sprite_index][normalized_angle] then
      return Rotator.cache[sprite_index][normalized_angle]
   end

   -- Create rotated sprite
   local src_ud = get_spr(sprite_index)

   -- Safety check if get_spr returns nil or invalid type (though manual says it returns userdata u8)
   if not src_ud then
      return sprite_index
   end

   local w, h = src_ud:width(), src_ud:height()

   -- Swap dimensions for 90/270 degrees
   local dest_w, dest_h = w, h
   if normalized_angle == 90 or normalized_angle == 270 then
      dest_w, dest_h = h, w
   end

   local dest_ud = userdata("u8", dest_w, dest_h)

   for y = 0, h - 1 do
      for x = 0, w - 1 do
         local val = src_ud:get(x, y)
         local dx, dy

         if normalized_angle == 90 then
            -- (x, y) -> (h - 1 - y, x)
            dx = h - 1 - y
            dy = x
         elseif normalized_angle == 180 then
            -- (x, y) -> (w - 1 - x, h - 1 - y)
            dx = w - 1 - x
            dy = h - 1 - y
         elseif normalized_angle == 270 then
            -- (x, y) -> (y, w - 1 - x)
            dx = y
            dy = w - 1 - x
         end

         dest_ud:set(dx, dy, val)
      end
   end

   Rotator.cache[sprite_index][normalized_angle] = dest_ud
   return dest_ud
end

-- Clear cache if needed (e.g. level change)
function Rotator.clear_cache()
   Rotator.cache = {}
end

return Rotator
