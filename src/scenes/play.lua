local GameState = require("src/game/game_state")
local World = require("src/world")
local Entities = require("src/entities")
local Systems = require("src/systems")
local Emotions = require("src/systems/emotions")
local Events = require("src/game/events")
local UI = require("src/ui")
local Wander = require("src/ai/primitives/wander")

local DungeonManager = World.DungeonManager
local CameraManager = World.CameraManager
local RoomRenderer = World.RoomRenderer
local Minimap = UI.Minimap

local SceneManager = require("src/scenes/manager")

local Play = SceneManager:addState("Play")

world = eggs()
local player
local camera_manager
local current_room

function Play:enteredState()
   Log.trace("Entered Play scene")
   world = eggs() -- MUST re-initialize world on every entry for Restart to work
   Systems.init_extended_palette()
   Systems.init_spotlight()
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

   local hitboxes_toggle = debugui.create_toggle(7, debugui.config._ACCENT3_color, "show_hitboxes",
      function(self) sync_toggle_visual(self, GameState.debug.show_hitboxes) end,
      nil,
      function(self) GameState.debug.show_hitboxes = not GameState.debug.show_hitboxes end)
   add(debugui.elements, hitboxes_toggle)

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
   Systems.Spawner.update(world, current_room)

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
   world.sys("map_collidable,velocity", function(e)
      Systems.resolve_map(e, current_room, camera_manager)
   end)()
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
   world.sys("collidable,velocity", Systems.resolve_entities)()
   world.sys("collidable,player", Systems.resolve_entities)()       -- Ensure player checks even if idle
   world.sys("collidable,melee_hitbox", Systems.resolve_entities)() -- Melee hitbox vs Enemy collision

   -- Timers & Health (self-iterating)
   Systems.health_regen(world)
   Systems.timers(world)

   -- Shadows (self-iterating)
   Systems.sync_shadows(world)

   -- Effects
   Systems.Effects.update_shake()
   Systems.FloatingText.update()

   if keyp("f2") then
      GameState.debug.show_hitboxes = not GameState.debug.show_hitboxes
      GameState.debug.show_grid = not GameState.debug.show_grid
   end
   if keyp("f3") then
      GameState.cheats.godmode = not GameState.cheats.godmode
   end
   if keyp("f4") then
      GameState.cheats.free_attacks = not GameState.cheats.free_attacks
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
   if camera_manager:is_scrolling() then
      local old_room = camera_manager.old_room
      local new_room = camera_manager.new_room

      -- Set both rooms as visible during transition
      Systems.set_active_rooms({
         old_room.grid_x..","..old_room.grid_y,
         new_room.grid_x..","..new_room.grid_y
      })

      clip_square = RoomRenderer.draw_scrolling(camera_manager, cam_x, cam_y)
      RoomRenderer.draw_room_features(old_room)
      RoomRenderer.draw_room_features(new_room)
   else
      -- Set only current room as visible
      Systems.set_active_rooms({current_room.grid_x..","..current_room.grid_y})

      clip_square = RoomRenderer.draw_exploring(current_room, cam_x, cam_y)
      RoomRenderer.draw_room_features(current_room)
   end

   -- Lighting (self-iterating)
   Systems.lighting(world, clip_square)

   -- 1. Background Layer: Shadows, Pickups
   Systems.draw_shadows(world, clip_square)
   Systems.draw_layer(world, "background,drawable", false)

   -- 2. Middleground Layer: Characters (Y-Sorted)
   Systems.draw_layer(world, "middleground,drawable", true)
   Emotions.draw(world)
   Systems.FloatingText.draw()

   -- 3. Global Effects & Debug
   Systems.apply_palette_swaps(world)
   Systems.Spawner.draw(current_room)

   pal()

   -- 4. Foreground Layer: Entity UI (Health Bars, Hitboxes)
   Systems.draw_health_bars(world)
   Systems.draw_aim_lines(world)

   if GameState.debug.show_hitboxes then
      Systems.draw_hitboxes(world)
   end
   -- if GameState.debug.show_grid then
   --    RoomRenderer.draw_debug_grid(current_room)
   -- end

   -- Reset camera for global UI
   camera()

   -- Draw HUD (Inventory)
   UI.Hud.draw(player)

   -- Draw minimap
   Minimap.draw(current_room)

   -- draw combat timer
   if current_room.combat_timer and current_room.combat_timer >= 0 then
      local timer = current_room.combat_timer
      local minutes = math.floor(timer / 60)
      local seconds = timer % 60
      local timer_str = string.format("%02d:%02d", minutes, seconds)
      print(timer_str, 10, 10, 8)
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
