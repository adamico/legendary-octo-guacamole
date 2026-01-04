local GameState = require("src/game/game_state")
local GameConstants = require("src/game/game_config")
local World = require("src/world")
local Entities = require("src/entities")
local Systems = require("src/systems")
local Emotions = require("src/systems/emotions")
local Events = require("src/game/events")
local UI = require("src/ui")
local Wander = require("src/ai/primitives/wander")
local AI = require("src/ai")
local Leveling = require("src/utils/leveling")
local Particles = require("src/systems/particles")

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
   Particles.init()

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

   fetch(CARTPATH.."sfx/game.sfx"):poke(0x80000) -- load 256k into 0x80000..0xbffff
   music(0, nil, nil, 0x80000) -- play music using 0x80000 as the audio base address
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
      -- Clean up enemies when unlock_all_rooms cheat is active
      if GameState.cheats.unlock_all_rooms then
         world.sys("enemy", function(e) world.del(e) end)()
      end
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
      if new_room.room_type ~= "combat" then
         fetch(CARTPATH.."sfx/"..new_room.room_type..".sfx"):poke(0x80000) -- load 256k into 0x80000..0xbffff
         music(0, nil, nil, 0x80000) -- play music using 0x80000 as the audio base address
      end
   end)

   -- Subscribe to Level Up event
   Events.on(Events.LEVEL_UP, function(player_entity, new_level)
      self:pushState("LevelUp", player_entity)
   end)

   -- Subscribe to Game Over event
   Events.on(Events.GAME_OVER, function()
      self:gotoState("GameOver")
   end)

   Events.on(Events.VICTORY, function()
      self:gotoState("Victory")
   end)

   -- Subscribe to room clear events
   Events.on(Events.ROOM_CLEAR, function(room)
      -- No healing on room clear anymore (as per new design)
      -- REFACTOR: Use SoundManager.play("room_clear") or similar
      sfx(10) -- room clear sound
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

   local unlock_rooms_toggle = debugui.create_toggle(7, debugui.config._ACCENT3_color, "unlock_all_rooms",
      function(self) sync_toggle_visual(self, GameState.cheats.unlock_all_rooms) end,
      nil,
      function(self) GameState.cheats.unlock_all_rooms = not GameState.cheats.unlock_all_rooms end)
   add(debugui.elements, unlock_rooms_toggle)

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
            "shot_speed: "..tostring(player.shot_speed),
            "range: "..tostring(player.range),
            "fire_rate: "..tostring(player.fire_rate),
            "[== mutations ==]",
            "Broodmother: "..tostring(player.mutations.Broodmother),
            "Eggsaggerated: "..tostring(player.mutations.Eggsaggerated),
            "Pureblood: "..tostring(player.mutations.Pureblood),
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

   -- Effects & Particles
   Systems.Effects.update_shake()
   Systems.Effects.update_animations(world)
   Systems.FloatingText.update()
   Particles.update()

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
   if keyp("f6") then
      GameState.cheats.unlock_all_rooms = not GameState.cheats.unlock_all_rooms
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

      if GameState.debug.show_grid then
         RoomRenderer.draw_debug_grid(current_room)
      end
   end

   -- Lighting (self-iterating)
   Systems.lighting(world, clip_square)

   -- 1. Background Layer: Shadows, Pickups
   Systems.draw_shadows(world, clip_square)
   Systems.draw_layer(world, "background,drawable", false)

   -- Boss Telegraphs (drawn behind entities but above background)
   UI.Hud.draw_boss_telegraphs(world)

   -- 2. Middleground Layer: Characters (Y-Sorted)
   Systems.draw_layer(world, "middleground,drawable", true)
   Emotions.draw(world)

   -- Particles clipped to room inner bounds (excludes walls)
   local inner = current_room:get_inner_bounds()
   local particle_clip = {
      x = inner.x1 * 16 - cam_x,
      y = inner.y1 * 16 - cam_y,
      w = (inner.x2 - inner.x1 + 1) * 16,
      h = (inner.y2 - inner.y1 + 1) * 16
   }
   Particles.draw(particle_clip)
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

   -- Pathfinding Debug: Show chick paths and targets
   if GameState.debug.show_pathfinding then
      local PathFollow = require("src/ai/primitives/path_follow")
      local HitboxUtils = require("src/utils/hitbox_utils")
      world.sys("minion", function(e)
         if e.minion_type == "Chick" then
            -- Draw current path (green if exists)
            PathFollow.debug_draw(e, 11) -- Green path

            -- Draw FSM state above chick
            local state_name = e.chick_fsm and e.chick_fsm.current or "none"
            print(state_name, e.x - 16, e.y - 32, 7) -- White state name (higher up)

            -- Draw attack range circle (light blue - melee range)
            local attack_range = e.attack_range or 20
            circ(e.x + 8, e.y + 8, attack_range, 12) -- Light blue attack range

            -- Draw line to chase target
            if e.chase_target then
               local hb = HitboxUtils.get_hitbox(e)
               local ex, ey = hb.x + hb.w / 2, hb.y + hb.h / 2
               local thb = HitboxUtils.get_hitbox(e.chase_target)
               local tx, ty = thb.x + thb.w / 2, thb.y + thb.h / 2

               -- Calculate distance
               local dx, dy = tx - ex, ty - ey
               local dist = sqrt(dx * dx + dy * dy)

               -- Check if using direct fallback (no valid path)
               local has_path = e.path_state and e.path_state.path and #e.path_state.path > 0
               if has_path then
                  line(ex, ey, tx, ty, 11)              -- Green = has path
                  circfill(tx, ty, 4, 11)               -- Target circle
               else
                  line(ex, ey, tx, ty, 8)               -- Red = NO PATH (direct fallback!)
                  circfill(tx, ty, 4, 8)                -- Red target
                  print("NO PATH", ex - 16, ey - 16, 8) -- Alert text
               end

               -- Show distance vs attack range
               local in_range = dist < attack_range
               local range_text = string.format("d:%.0f/%.0f", dist, attack_range)
               print(range_text, ex - 20, ey - 32, in_range and 11 or 8)
            end
         end
      end)()
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
   UI.Hud.draw_inventory(player)

   -- Draw mutations
   UI.Hud.draw_mutations(player)

   -- Draw Boss Health Bar (if boss is present)
   UI.Hud.draw_boss_health(world)

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
