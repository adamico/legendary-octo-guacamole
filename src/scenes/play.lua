local GameState = require("src/game/game_state")
local GameConstants = require("src/game/game_config")
local World = require("src/world")
local picobloc = require("lib/picobloc/picobloc")
local register_components = require("src/components")
local Entities = require("src/entities")
local Systems = require("src/systems")
local Emotions = require("src/systems/emotions")
local Events = require("src/game/events")
local UI = require("src/ui")
local AIDebug = require("src/systems/ai_debug")
local Leveling = require("src/utils/leveling")
local DebugUI = require("src/ui/debug_ui")
local PlayEvents = require("src/scenes/play_events")

local DungeonManager = World.DungeonManager
local CameraManager = World.CameraManager
local RoomRenderer = World.RoomRenderer
local Minimap = UI.Minimap

local SceneManager = require("src/scenes/manager")

local Play = SceneManager:addState("Play")

--- @type ECSWorld
local world -- Global world instance (initialized later)
local player
local camera_manager
local current_room

function Play:enteredState()
   Log.trace("Entered Play scene")
   --- @type ECSWorld
   world = picobloc.World()   -- MUST re-initialize ECS world on every entry for restart to work
   register_components(world) -- Register all ECS components
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

   -- Subscribe to events (room transition, level up, game over)
   PlayEvents.subscribe({
      get_world = function() return world end,
      get_player = function() return player end,
      get_current_room = function() return current_room end,
      set_current_room = function(room) current_room = room end,
      get_camera_manager = function() return camera_manager end,
      minimap = Minimap,
      scene = self
   })

   -- Setup debug UI (cheats, debug toggles, player stats)
   DebugUI.init(function() return player end, function() return world end)

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
   Systems.read_input(world)

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
