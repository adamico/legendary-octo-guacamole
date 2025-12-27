local GameConstants = require("src/game/game_config")
local GameState = require("src/game/game_state")
local World = require("src/world")
local Entities = require("src/entities")
local Systems = require("src/systems")
local Emotions = require("src/systems/emotions")
local Events = require("src/game/events")
local UI = require("src/ui")

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
      camera_manager:set_room(current_room)
      DungeonManager.setup_room(current_room, player, world)
      Minimap.visit(current_room) -- Mark new room as visited
      world.sys("projectile", function(e) world.del(e) end)()
      world.sys("pickup", function(e) world.del(e) end)()
      world.sys("skull", function(e) world.del(e) end)()
      Systems.FloatingText.clear()
   end)

   -- Subscribe to Game Over event
   Events.on(Events.GAME_OVER, function()
      self:gotoState("GameOver")
   end)

   -- Subscribe to room clear events (heal player by 1 segment)
   Events.on(Events.ROOM_CLEAR, function(room)
      local segment_hp = player.max_hp / 5
      local old_hp = player.hp
      player.hp = min(player.hp + segment_hp, player.max_hp)
      local actual_heal = player.hp - old_hp
      if actual_heal > 0 then
         Systems.FloatingText.spawn_at_entity(player, actual_heal, "heal")
      end
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

   -- Update spawner
   Systems.Spawner.update(world, current_room)

   -- Check room clear
   DungeonManager.check_room_clear(current_room, world)

   -- Input
   world.sys("controllable", Systems.read_input)()

   -- Melee (health-gated attack)
   Systems.melee(world)

   -- Physics (self-iterating)
   Systems.acceleration(world)
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
   world.sys("collidable", Systems.resolve_entities)()

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

      clip_square = RoomRenderer.draw_scrolling(camera_manager, cam_x, cam_y)
      RoomRenderer.draw_doors(old_room)
      RoomRenderer.draw_doors(new_room)
   else
      clip_square = RoomRenderer.draw_exploring(current_room, cam_x, cam_y)
      RoomRenderer.draw_doors(current_room)
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
   if GameState.debug.show_hitboxes then
      Systems.draw_hitboxes(world)
   end

   -- Reset camera for global UI
   camera()

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
