local MathUtils = {}

--- Check if a line segment intersects an AABB (Axis-Aligned Bounding Box)
--- @param x1 number Segment start X
--- @param y1 number Segment start Y
--- @param x2 number Segment end X
--- @param y2 number Segment end Y
--- @param bx number Box X (top-left)
--- @param by number Box Y (top-left)
--- @param bw number Box Width
--- @param bh number Box Height
--- @return boolean
function MathUtils.segment_intersects_aabb(x1, y1, x2, y2, bx, by, bw, bh)
   -- 1. Check if the segment's bounding box intersects the AABB (Broad phase)
   local min_x = min(x1, x2)
   local max_x = max(x1, x2)
   local min_y = min(y1, y2)
   local max_y = max(y1, y2)

   if max_x < bx or min_x > bx + bw or max_y < by or min_y > by + bh then
      return false
   end

   -- 2. Check overlap logic using the slab method or similar
   -- Since we are in 2D, we can check intersection with the four lines of the box
   -- simple Liang-Barsky line clipping algorithm is robust here

   local t0, t1 = 0, 1
   local dx = x2 - x1
   local dy = y2 - y1

   local p = {-dx, dx, -dy, dy}
   local q = {x1 - bx, bx + bw - x1, y1 - by, by + bh - y1}

   for i = 1, 4 do
      if p[i] == 0 then
         -- Line is parallel to this boundary
         if q[i] < 0 then return false end    -- Outside boundary
      else
         local t = q[i] / p[i]
         if p[i] < 0 then
            if t > t1 then return false end
            if t > t0 then t0 = t end
         else
            if t < t0 then return false end
            if t < t1 then t1 = t end
         end
      end
   end

   return true
end

return MathUtils
