-- Menu Navigation Module
-- Provides keyboard/gamepad navigation for pgui menus alongside mouse input

local MenuNav = {}

--- Create a new menu navigation instance
--- @param num_buttons Number of buttons in the menu
--- @return Navigation state table with methods
function MenuNav.new(num_buttons)
   local nav = {
      selected_index = 1,
      num_buttons = num_buttons or 1,
      button_rects = {},
      using_keyboard = true,
      last_mouse_x = 0,
      last_mouse_y = 0,
   }
   
   setmetatable(nav, {__index = MenuNav})
   return nav
end

-- Reset navigation state (call in enteredState)
function MenuNav:reset()
   self.selected_index = 1
   self.button_rects = {}
   self.using_keyboard = true
   self.last_mouse_x = 0
   self.last_mouse_y = 0
end

-- Check if up navigation is pressed
function MenuNav.nav_up()
   return btnp(2) or btnp(10) -- up on either d-pad
end

-- Check if down navigation is pressed
function MenuNav.nav_down()
   return btnp(3) or btnp(11) -- down on either d-pad
end

-- Check if confirm button is pressed
function MenuNav.nav_confirm()
   return btnp(4) or btnp(12) -- O button on either d-pad
end

--- Update navigation state based on input
--- @param pgui table The pgui instance to check mouse state
--- @return boolean
function MenuNav:update(pgui)
   -- Detect input mode changes (mouse movement)
   local current_mouse_x = pgui.stats.mouse.mx
   local current_mouse_y = pgui.stats.mouse.my
   local mouse_moved = (current_mouse_x ~= self.last_mouse_x) or (current_mouse_y ~= self.last_mouse_y)
   
   if mouse_moved then
      self.using_keyboard = false
      self.last_mouse_x = current_mouse_x
      self.last_mouse_y = current_mouse_y
   end
   
   -- Handle keyboard navigation
   if MenuNav.nav_up() then
      self.selected_index = self.selected_index - 1
      if self.selected_index < 1 then self.selected_index = self.num_buttons end
      self.using_keyboard = true
   end
   if MenuNav.nav_down() then
      self.selected_index = self.selected_index + 1
      if self.selected_index > self.num_buttons then self.selected_index = 1 end
      self.using_keyboard = true
   end
   
   return MenuNav.nav_confirm() and self.using_keyboard
end

--- Calculate button rectangles for a vertical stack
--- @param stack_pos vec position of the vstack
--- @param num_buttons Number of buttons
--- @param max_width Maximum text width in characters
--- @param margin Button margin
--- @param gap Gap between buttons
function MenuNav:calculate_button_rects(stack_pos, num_buttons, max_width, margin, gap)
   local button_height = 6 + margin * 2
   self.button_rects = {}
   for i = 1, num_buttons do
      local btn_x = stack_pos.x
      local btn_y = stack_pos.y + (i - 1) * (button_height + gap)
      local btn_w = max_width * 5 + margin * 2
      local btn_h = button_height
      self.button_rects[i] = {x = btn_x, y = btn_y, w = btn_w, h = btn_h}
   end
end

--- Apply hover state by moving virtual mouse to selected button
--- Call this BEFORE creating the pgui vstack component
--- @param pgui table The pgui instance
function MenuNav:apply_hover(pgui)
   if self.using_keyboard then
      local selected_btn = self.button_rects[self.selected_index]
      if selected_btn then
         pgui.stats.mouse.mx = selected_btn.x + selected_btn.w / 2
         pgui.stats.mouse.my = selected_btn.y + selected_btn.h / 2
      end
   end
end

--- Check if a specific button index should be activated
--- @param index Button index to check
--- @param pgui_clicked Whether pgui detected a click on this button
--- @param confirmed Whether keyboard confirm was pressed
--- @return false|true if this button should be activated
function MenuNav:is_activated(index, pgui_clicked, confirmed)
   if pgui_clicked then return true end
   if confirmed and self.selected_index == index then return true end
   return false
end

return MenuNav
