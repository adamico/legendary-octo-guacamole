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
--- @param ctx table Context containing get_world, get_player, set_current_room, get_camera_manager, minimap, scene
function PlayEvents.subscribe(ctx)
   -- Subscribe to room transition events
   Events.on(Events.ROOM_TRANSITION, function(new_room)
      local world = ctx.get_world()
      local player = ctx.get_player()

      ctx.set_current_room(new_room)
      DungeonManager.current_room = new_room
      ctx.get_camera_manager():set_room(new_room)
      DungeonManager.setup_room(new_room, player, world)
      ctx.minimap.visit(new_room)

      -- Remove projectiles, pickups, skulls from previous room
      for _, tag in ipairs({"projectile", "pickup", "skull"}) do
         world:query({tag}, function(ids)
            for i = ids.first, ids.last do world:remove_entity(ids[i]) end
         end)
      end

      -- Teleport minions to player in new room
      world:query({"minion", "position"}, function(ids, pos)
         for i = ids.first, ids.last do
            pos.x[i] = player.x
            pos.y[i] = player.y
            -- Reset behavior if chick
            local e = EntityProxy.new(world, ids[i])
            if e.chick_fsm then
               Wander.reset(e)
            end
         end
      end)

      Systems.FloatingText.clear()
      AI.ChickAI.clear_target()
   end)

   -- Subscribe to Level Up event
   Events.on(Events.LEVEL_UP, function(player_entity, new_level)
      ctx.scene:pushState("LevelUp", player_entity)
   end)

   -- Subscribe to Game Over event
   Events.on(Events.GAME_OVER, function()
      ctx.scene:gotoState("GameOver")
   end)
end

return PlayEvents
