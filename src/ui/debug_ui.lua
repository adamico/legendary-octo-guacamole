-- Debug UI setup for Play scene
-- Creates debugui toggles for cheats, debug options, and player stats display

local GameState = require("src/game/game_state")
local EntityProxy = require("src/utils/entity_proxy")

local DebugUI = {}

-- Helper to sync toggle visual state without triggering tap callback
local function sync_toggle_visual(toggle, cheat_value)
   if toggle.on ~= cheat_value then
      toggle.on = cheat_value
      -- Swap colors to reflect state
      toggle.bg_col, toggle.text_col = toggle.text_col, toggle.bg_col
   end
end

--- Initialize debug UI elements for the Play scene
--- @param get_player fun(): EntityID Function that returns the player entity ID
--- @param get_world fun(): ECSWorld Function that returns the ECS world
function DebugUI.init(get_player, get_world)
   -- Cheats Group
   add(debugui.elements, debugui.create_group(7, debugui.config._ACCENT1_color, true, function(self)
      self.vars = {"[== cheats ==]"}
   end))

   local godmode_toggle = debugui.create_toggle(7, debugui.config._ACCENT3_color, "godmode",
      function(self) sync_toggle_visual(self, GameState.cheats.godmode) end,
      nil,
      function(self) GameState.cheats.godmode = not GameState.cheats.godmode end)
   add(debugui.elements, godmode_toggle)

   local free_attacks_toggle = debugui.create_toggle(7, debugui.config._ACCENT3_color, "free_attacks",
      function(self) sync_toggle_visual(self, GameState.cheats.free_attacks) end,
      nil,
      function(self) GameState.cheats.free_attacks = not GameState.cheats.free_attacks end)
   add(debugui.elements, free_attacks_toggle)

   local infinite_inv_toggle = debugui.create_toggle(7, debugui.config._ACCENT3_color, "infinite_inventory",
      function(self) sync_toggle_visual(self, GameState.cheats.infinite_inventory) end,
      nil,
      function(self) GameState.cheats.infinite_inventory = not GameState.cheats.infinite_inventory end)
   add(debugui.elements, infinite_inv_toggle)

   -- Debug Group
   add(debugui.elements, debugui.create_group(7, debugui.config._ACCENT1_color, true, function(self)
      self.vars = {"[== debug ==]"}
   end))

   local hitboxes_toggle = debugui.create_toggle(7, debugui.config._ACCENT3_color, "show_hitboxes",
      function(self) sync_toggle_visual(self, GameState.debug.show_hitboxes) end,
      nil,
      function(self) GameState.debug.show_hitboxes = not GameState.debug.show_hitboxes end)
   add(debugui.elements, hitboxes_toggle)

   local grid_toggle = debugui.create_toggle(7, debugui.config._ACCENT3_color, "show_grid",
      function(self) sync_toggle_visual(self, GameState.debug.show_grid) end,
      nil,
      function(self) GameState.debug.show_grid = not GameState.debug.show_grid end)
   add(debugui.elements, grid_toggle)

   local combat_timer_toggle = debugui.create_toggle(7, debugui.config._ACCENT3_color, "show_combat_timer",
      function(self) sync_toggle_visual(self, GameState.debug.show_combat_timer) end,
      nil,
      function(self) GameState.debug.show_combat_timer = not GameState.debug.show_combat_timer end)
   add(debugui.elements, combat_timer_toggle)

   local pathfinding_toggle = debugui.create_toggle(7, debugui.config._ACCENT3_color, "show_pathfinding",
      function(self) sync_toggle_visual(self, GameState.debug.show_pathfinding) end,
      nil,
      function(self) GameState.debug.show_pathfinding = not GameState.debug.show_pathfinding end)
   add(debugui.elements, pathfinding_toggle)

   -- Player Stats Group (Real-time monitoring)
   local stats_group = debugui.create_group(7, debugui.config._ACCENT2_color, true,
      function(self)
         local player = get_player()
         local world = get_world()
         if not player or not world:entity_exists(player) then return end
         local p = EntityProxy.new(world, player)
         self.vars = {
            "[== player stats ==]",
            "hp: "..tostring(p.hp).."/"..tostring(p.max_hp),
            "overheal: "..tostring(p.overflow_hp or 0),
            "damage: "..tostring(p.impact_damage),
            "shot_speed: "..tostring(p.shot_speed),
            "range: "..tostring(p.range),
            "fire_rate: "..tostring(p.fire_rate),
            "[== inventory ==]",
            "coins: "..tostring(p.coins),
            "keys: "..tostring(p.keys),
            "bombs: "..tostring(p.bombs),
            "[== xp ==]",
            "level: "..tostring(p.level),
            "xp: "..tostring(p.xp).."/"..tostring(p.xp_to_next_level),
            "[== level ==]",
            "seed: "..tostring(GameState.current_seed),
         }
      end)
   add(debugui.elements, stats_group)
end

return DebugUI
