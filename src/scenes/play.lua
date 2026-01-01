local GameState = require("src/game/game_state")
local GameConstants = require("src/game/game_config")
local World = require("src/world")
local ECS = require("lib/picobloc/picobloc")
local Entities = require("src/entities")
local Systems = require("src/systems")
local Emotions = require("src/systems/emotions")
local Events = require("src/game/events")
local UI = require("src/ui")
local Wander = require("src/ai/primitives/wander")
local AI = require("src/ai")
local AIDebug = require("src/systems/ai_debug")
local Leveling = require("src/utils/leveling")

local DungeonManager = World.DungeonManager
local CameraManager = World.CameraManager
local RoomRenderer = World.RoomRenderer
local Minimap = UI.Minimap

local SceneManager = require("src/scenes/manager")

local Play = SceneManager:addState("Play")

world = ECS:new()
local player
local camera_manager
local current_room

function Play:enteredState()
   Log.trace("Entered Play scene")
   world = ECS:new() -- MUST re-initialize ECS world on every entry for restart to work
   Systems.init_extended_palette()
   Systems.init_spotlight()
   Systems.FloatingText.set_world(world) -- Initialize FloatingText with proper ECS world

   -- Initialize level seed for reproducible dungeon generation
   local seed = GameState.level_seed or flr(time() * 1000)
   srand(seed)
   GameState.current_seed = seed
   Log.info("Level seed: "..seed)

   DungeonManager.init()

   -- Spawn player at center of start room (World Pixels)
   local room = DungeonManager.current_room
   local px = room.pixels.x + room.pixels.w / 2
   local py = room.pixels.y + room.pixels.h / 2
   player = Entities.spawn_player(world, px, py)

   -- Initialize camera
   camera_manager = CameraManager:new(player)
   current_room = room
   camera_manager:set_room(current_room)

   -- Initialize minimap and mark starting room as visited
   Minimap.init()
   Minimap.visit(current_room)

   -- Subscribe to room transition events
   Events.on(Events.ROOM_TRANSITION, function(new_room)
      current_room = new_room
      DungeonManager.current_room = new_room
      camera_manager:set_room(current_room)
      DungeonManager.setup_room(current_room, player, world)
      Minimap.visit(current_room) -- Mark new room as visited
      world.sys("projectile", function(e) world.del(e) end)()
      world.sys("pickup", function(e) world.del(e) end)()
      world.sys("skull", function(e) world.del(e) end)()
      -- Teleport minions to player in new room
      world.sys("minion", function(e)
         e.x = player.x
         e.y = player.y
         if e.chick_fsm then
            -- Reset behavior
            Wander.reset(e)
         end
      end)()
      Systems.FloatingText.clear()
      AI.ChickAI.clear_target() -- Clear painted target from previous room
   end)

   -- Subscribe to Level Up event
   Events.on(Events.LEVEL_UP, function(player_entity, new_level)
      self:pushState("LevelUp", player_entity)
   end)

   -- Subscribe to Game Over event
   Events.on(Events.GAME_OVER, function()
      self:gotoState("GameOver")
   end)

   -- Subscribe to room clear events
   Events.on(Events.ROOM_CLEAR, function(room)
      -- No healing on room clear anymore (as per new design)
   end)

   -- Setup debugui cheats toggles (clickable)
   -- Helper to sync toggle visual state without triggering tap callback
   local function sync_toggle_visual(toggle, cheat_value)
      if toggle.on ~= cheat_value then
         toggle.on = cheat_value
         -- Swap colors to reflect state
         toggle.bg_col, toggle.text_col = toggle.text_col, toggle.bg_col
      end
   end

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
         if not player then return end
         self.vars = {
            "[== player stats ==]",
            "hp: "..tostring(player.hp).."/"..tostring(player.max_hp),
            "overheal: "..tostring(player.overflow_hp or 0),
            "damage: "..tostring(player.damage),
            "shot_speed: "..tostring(player.shot_speed),
            "range: "..tostring(player.range),
            "fire_rate: "..tostring(player.fire_rate),
            "[== inventory ==]",
            "coins: "..tostring(player.coins),
            "keys: "..tostring(player.keys),
            "bombs: "..tostring(player.bombs),
            "[== xp ==]",
            "level: "..tostring(player.level),
            "xp: "..tostring(player.xp).."/"..tostring(player.xp_to_next_level),
            "[== level ==]",
            "seed: "..tostring(GameState.current_seed),
         }
      end)
   add(debugui.elements, stats_group)

   -- Setup initial room
   DungeonManager.setup_room(current_room, player, world)
end

function Play:update()
   -- Update camera
   camera_manager:update()

   -- If scrolling, skip all gameplay systems
   if camera_manager:is_scrolling() then
      return
   end

   -- Update minimap logic (trigger detection and tweening)
   Minimap.update_trigger(player, camera_manager)
   Minimap.update()

   -- Update spawner
   Systems.Spawner.update(world, current_room, player)

   -- Check room clear
   DungeonManager.check_room_clear(current_room, world)

   -- Input
   world.sys("controllable", Systems.read_input)()

   -- Melee (health-gated attack)
   Systems.melee(world)

   -- Bomber (bomb placement and fuse countdown)
   Systems.bomber(world)

   -- Physics (self-iterating)
   Systems.acceleration(world)
   Systems.z_axis(world)
   Systems.knockback_pre(world) -- Add knockback to velocity before collision
   Systems.resolve_map_all(world, current_room, camera_manager)
   Systems.velocity(world)
   Systems.knockback_post(world) -- Decay knockback after movement

   -- Animation & Lifecycle (self-iterating)
   Systems.update_lifecycle(world)
   Systems.animation(world)

   -- Combat & AI (self-iterating)
   Systems.shooter(world)
   Systems.ai(world, player)
   Emotions.update(world)

   -- Resolve Entity Collisions (Optimized with single grid build)
   Systems.update_spatial_grid(world)
   Systems.resolve_all(world)

   -- Timers & Health (self-iterating)
   Systems.health_regen(world)
   Systems.timers(world)

   -- Shadows (self-iterating)
   Systems.sync_shadows(world)

   -- Effects
   Systems.Effects.update_shake()
   Systems.FloatingText.update(world)

   -- Leveling (check for level ups after XP collection)
   Leveling.check_level_up(player)

   if keyp("f2") then
      GameState.debug.show_hitboxes = not GameState.debug.show_hitboxes
      GameState.debug.show_grid = not GameState.debug.show_grid
      GameState.debug.show_combat_timer = not GameState.debug.show_combat_timer
   end
   if keyp("f3") then
      GameState.cheats.godmode = not GameState.cheats.godmode
   end
   if keyp("f4") then
      GameState.cheats.free_attacks = not GameState.cheats.free_attacks
   end
   if keyp("f5") then
      GameState.cheats.infinite_inventory = not GameState.cheats.infinite_inventory
   end
end

function Play:draw()
   cls(0)

   local sx, sy = camera_manager:get_offset()
   local shake = Systems.Effects.get_shake_offset()
   local cam_x = sx + shake.x
   local cam_y = sy + shake.y
   camera(cam_x, cam_y)

   local clip_square
   local visible_rooms = {}
   if camera_manager:is_scrolling() then
      local old_room = camera_manager.old_room
      local new_room = camera_manager.new_room

      -- Set both rooms as visible during transition
      visible_rooms[old_room.grid_x..","..old_room.grid_y] = true
      visible_rooms[new_room.grid_x..","..new_room.grid_y] = true

      clip_square = RoomRenderer.draw_scrolling(camera_manager, cam_x, cam_y)
      RoomRenderer.draw_room_features(old_room)
      RoomRenderer.draw_room_features(new_room)
   else
      -- Set only current room as visible
      visible_rooms[current_room.grid_x..","..current_room.grid_y] = true

      clip_square = RoomRenderer.draw_exploring(current_room, cam_x, cam_y)
      RoomRenderer.draw_room_features(current_room)

      if GameState.debug.show_grid then
         RoomRenderer.draw_debug_grid(current_room)
      end
   end

   -- Lighting (self-iterating)
   Systems.lighting(world, clip_square)

   -- 1. Background Layer: Shadows, Pickups
   Systems.draw_shadows(world)
   Systems.draw_layer(world, "background,drawable", false, visible_rooms)

   -- 2. Middleground Layer: Characters (Y-Sorted)
   Systems.draw_layer(world, "middleground,drawable", true, visible_rooms)
   Emotions.draw(world)
   Systems.FloatingText.draw(world)

   -- 3. Global Effects & Debug
   Systems.Spawner.draw(current_room)

   pal()

   -- 4. Foreground Layer: Entity UI (Health Bars, Hitboxes)
   Systems.draw_health_bars(world)
   Systems.draw_aim_lines(world)

   if GameState.debug.show_hitboxes then
      Systems.draw_hitboxes(world)
   end

   -- Pathfinding Debug: Show chick paths and targets
   if GameState.debug.show_pathfinding then
      AIDebug.draw(world)
   end

   -- Shop Item Price Tags (world-space UI)
   if current_room and current_room.room_type == "shop" then
      UI.Hud.draw_shop_prices(world)
   end

   -- Reset camera for global UI
   camera()

   -- Draw HUD (Health Bar)
   UI.HealthBar.draw(player)

   -- Draw HUD (Inventory)
   UI.Hud.draw(player)

   -- Draw XP bar
   UI.XpBar.draw(player)

   -- Draw minimap
   Minimap.draw(current_room)

   -- draw combat timer (debug)
   if GameState.debug.show_combat_timer and current_room.combat_timer and current_room.combat_timer >= 0 then
      local config = GameConstants.Hud.combat_timer
      local timer = current_room.combat_timer
      local minutes = math.floor(timer / 60)
      local seconds = timer % 60
      local timer_str = string.format("%02d:%02d", minutes, seconds)
      print(timer_str, config.x, config.y, config.color)
   end
end

function Play:exitedState()
   Log.trace("Exited Play scene")
   Events.reset()  -- Clear all event subscriptions
   pal()           -- Reset GFX color remaps
   palt()          -- Reset transparency
   poke(0x550b, 0) -- Reset pen palette row to 0
end

return Play
