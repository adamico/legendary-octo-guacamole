-- Play scene event subscriptions
-- Handles room transitions, level ups, game over, and room clear events

local Events = require("src/game/events")
local World = require("src/world")
local Systems = require("src/systems")
local AI = require("src/ai")
local Wander = require("src/ai/primitives/wander")
local EntityProxy = require("src/utils/entity_proxy")

local DungeonManager = World.DungeonManager

local PlayEvents = {}

--- Subscribe to all Play scene events
--- @param context table Context containing get_world, get_player, get_current_room, set_current_room, get_camera_manager, minimap, scene
function PlayEvents.subscribe(context)
   local get_world = context.get_world
   local get_player = context.get_player
   local get_current_room = context.get_current_room
   local set_current_room = context.set_current_room
   local get_camera_manager = context.get_camera_manager
   local minimap = context.minimap
   local scene = context.scene

   -- Subscribe to room transition events
   Events.on(Events.ROOM_TRANSITION, function(new_room)
      local world = get_world()
      local player = get_player()
      local camera_manager = get_camera_manager()

      set_current_room(new_room)
      DungeonManager.current_room = new_room
      camera_manager:set_room(new_room)
      DungeonManager.setup_room(new_room, player, world)
      minimap.visit(new_room) -- Mark new room as visited

      -- Remove projectiles, pickups, skulls from previous room
      world:query({"projectile"}, function(ids)
         for i = ids.first, ids.last do world:remove_entity(ids[i]) end
      end)
      world:query({"pickup"}, function(ids)
         for i = ids.first, ids.last do world:remove_entity(ids[i]) end
      end)
      world:query({"skull"}, function(ids)
         for i = ids.first, ids.last do world:remove_entity(ids[i]) end
      end)

      -- Teleport minions to player in new room
      world:query({"minion", "position"}, function(ids, pos)
         for i = ids.first, ids.last do
            local p = EntityProxy.new(world, player)
            pos.x[i] = p.x
            pos.y[i] = p.y
            -- Reset behavior if chick
            local e = EntityProxy.new(world, ids[i])
            if e.chick_fsm then
               Wander.reset(e)
            end
         end
      end)

      Systems.FloatingText.clear()
      AI.ChickAI.clear_target() -- Clear painted target from previous room
   end)

   -- Subscribe to Level Up event
   Events.on(Events.LEVEL_UP, function(player_entity, new_level)
      scene:pushState("LevelUp", player_entity)
   end)

   -- Subscribe to Game Over event
   Events.on(Events.GAME_OVER, function()
      scene:gotoState("GameOver")
   end)

   -- Subscribe to room clear events
   Events.on(Events.ROOM_CLEAR, function(room)
      -- No healing on room clear anymore (as per new design)
   end)
end

return PlayEvents
