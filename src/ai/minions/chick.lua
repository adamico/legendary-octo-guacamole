-- Chick AI behavior
-- FSM: wandering <-> seeking_food <-> chasing <-> attacking
-- Priority: hungry > enemy in range > wander
-- Uses A* pathfinding for navigation

local machine = require("lib/lua-state-machine/statemachine")
local Wander = require("src/ai/primitives/wander")
local Chase = require("src/ai/primitives/chase")
local PathFollow = require("src/ai/primitives/path_follow")
local SeekFood = require("src/ai/primitives/seek_food")
local FloatingText = require("src/systems/floating_text")
local Emotions = require("src/systems/emotions")
local HitboxUtils = require("src/utils/hitbox_utils")
local DungeonManager = require("src/world/dungeon_manager")

-- Target painting: enemy hit by player becomes priority target for all chicks
local painted_target = nil

local function init_fsm(entity)
   entity.chick_fsm = machine.create({
      initial = "wandering",
      events = {
         {
            name = "get_hungry",
            from = {"wandering", "chasing", "attacking", "following"},
            to = "seeking_food"
         },
         {
            name = "spot_enemy",
            from = {"wandering", "seeking_food", "following"},
            to = "chasing"
         },
         {
            name = "reach_enemy",
            from = "chasing",
            to = "attacking"
         },
         {
            name = "lose_target",
            from = {"chasing", "attacking"},
            to = "wandering"
         },
         {
            name = "back_off",
            from = "attacking",
            to = "chasing"
         },
         {
            name = "eat_done",
            from = "seeking_food",
            to = "wandering"
         },
         {
            name = "start_following",
            from = "wandering",
            to = "following"
         },
         {
            name = "stop_following",
            from = "following",
            to = "wandering"
         },
      },
      callbacks = {
         onwandering = function(self, event, from, to) Emotions.set(entity, "idle") end,
         onseeking_food = function(self, event, from, to) Emotions.set(entity, "seeking_food") end,
         onchasing = function(self, event, from, to) Emotions.set(entity, "chasing") end,
         onfollowing = function(self, event, from, to) Emotions.set(entity, "following") end,
      }
   })
end

--- Find nearest enemy within vision range (current room only)
--- OPTIMIZED: Uses squared distances, takes pre-fetched room bounds
--- @param entity table - The chick
--- @param world table - ECS world
--- @param room_bounds table|nil - Pre-fetched room bounds
--- @return table|nil, number - Nearest enemy and distance squared (or nil if none)
local function find_nearest_enemy(entity, world, room_bounds)
   local vision_range = entity.vision_range
   local vision_range_sq = vision_range * vision_range
   local nearest_enemy = nil
   local nearest_dist_sq = vision_range_sq

   local ex, ey = entity.x, entity.y

   -- Target painting: If painted target exists and is alive, prioritize it
   if painted_target and painted_target.hp and painted_target.hp > 0 then
      local dx = painted_target.x - ex
      local dy = painted_target.y - ey
      local dist_sq = dx * dx + dy * dy
      -- Always target painted enemy if within extended vision (2x range)
      if dist_sq < vision_range_sq * 4 then
         return painted_target, dist_sq
      end
   else
      -- Clear stale painted target
      painted_target = nil
   end

   world.sys("enemy", function(enemy)
      -- Skip if enemy is outside current room bounds (padded by 1 tile to include walls)
      if room_bounds then
         local etx = flr(enemy.x / 16)
         local ety = flr(enemy.y / 16)
         -- Fix: Widen bounds by 1 to include enemies overlapping walls (e.g. Dashers)
         if etx < room_bounds.x1 - 1 or etx > room_bounds.x2 + 1 or
            ety < room_bounds.y1 - 1 or ety > room_bounds.y2 + 1 then
            return -- Skip enemies outside room
         end
      end

      local dx = enemy.x - ex
      local dy = enemy.y - ey
      local dist_sq = dx * dx + dy * dy
      if dist_sq < nearest_dist_sq then
         nearest_dist_sq = dist_sq
         nearest_enemy = enemy
      end
   end)()

   return nearest_enemy, nearest_dist_sq
end

--- Apply attack to target enemy
--- @param entity table - The chick
--- @param target table - The enemy being attacked
local function attack_enemy(entity, target)
   -- Check attack cooldown
   if entity.attack_timer and entity.attack_timer > 0 then
      return false -- Still on cooldown
   end

   -- Deal damage
   local damage = entity.attack_damage
   target.hp = target.hp - damage
   target.invuln_timer = 5 -- Brief invuln
   FloatingText.spawn_at_entity(target, -damage, "damage")

   -- Knockback the chick away from enemy (recoil)
   local dx = entity.x - target.x
   local dy = entity.y - target.y
   local len_sq = dx * dx + dy * dy
   if len_sq > 0 then
      local len = sqrt(len_sq)
      dx = dx / len
      dy = dy / len
   else
      dx, dy = 0, -1
   end

   local knockback = entity.attack_knockback
   entity.knockback_vel_x = dx * knockback
   entity.knockback_vel_y = dy * knockback

   -- Reset attack cooldown
   entity.attack_timer = entity.attack_cooldown

   return true
end

--- Main AI update for Chick minion
--- OPTIMIZED: Caches queries, uses squared distances, reduces redundant calculations
--- @param entity table - The chick entity
--- @param world table - ECS world
local function chick_ai(entity, world)
   -- Initialize FSM if needed
   if not entity.chick_fsm then
      init_fsm(entity)
   end

   -- Decrement attack timer
   if entity.attack_timer and entity.attack_timer > 0 then
      entity.attack_timer = entity.attack_timer - 1
   end

   -- Face-Hugger attachment: Skip normal AI while attached to enemy
   if entity.attachment_target then
      local target = entity.attachment_target

      -- Check if target is still valid (exists and alive)
      if target.hp and target.hp > 0 then
         -- Follow target position (stick to enemy)
         entity.x = target.x
         entity.y = target.y

         -- Attack while attached (guaranteed hits, no range check needed)
         if (entity.attack_timer or 0) <= 0 then
            attack_enemy(entity, target)
         end

         -- Decrement attachment timer
         entity.attachment_timer = (entity.attachment_timer or 0) - 1

         -- Detach when timer expires
         if entity.attachment_timer <= 0 then
            entity.attachment_target = nil
            -- Initialize FSM to wandering state after detaching
            if entity.chick_fsm then
               Emotions.set(entity, "idle")
            end
         end
      else
         -- Target died, detach immediately
         entity.attachment_target = nil
      end

      return -- Skip rest of AI while attached
   end

   local fsm = entity.chick_fsm

   -- OPTIMIZATION: Cache room and bounds once per frame
   local room = DungeonManager.current_room
   local room_bounds = room and room:get_inner_bounds()

   -- OPTIMIZATION: Cache player reference once per frame (avoid repeated ECS queries)
   local player = nil
   world.sys("player", function(p) player = p end)()

   -- OPTIMIZATION: Cache player hitbox center if player exists (reused multiple times)
   local player_cx, player_cy
   if player then
      local phb = HitboxUtils.get_hitbox(player)
      player_cx = phb.x + phb.w / 2
      player_cy = phb.y + phb.h / 2
   end

   -- Gather perception data
   local is_hungry = entity.hp < (entity.max_hp or 20) / 2
   local nearest_enemy, enemy_dist_sq = find_nearest_enemy(entity, world, room_bounds)
   local has_target = nearest_enemy ~= nil

   -- OPTIMIZATION: Use squared distances for range comparisons
   local attack_range_sq = entity.attack_range * entity.attack_range
   local in_attack_range = has_target and enemy_dist_sq < attack_range_sq

   -- State transitions based on priority: hungry > attack > chase > follow > wander
   -- Track previous target to detect target changes
   local prev_target = entity.chase_target

   if fsm:is("wandering") then
      if is_hungry then
         fsm:get_hungry()
      elseif has_target then
         fsm:spot_enemy()
         entity.chase_target = nearest_enemy
      elseif player then
         -- Check if we should start following player
         local dx = player.x - entity.x
         local dy = player.y - entity.y
         local dist_sq = dx * dx + dy * dy
         local trigger_dist = entity.follow_trigger_dist or 100
         local trigger_dist_sq = trigger_dist * trigger_dist

         if dist_sq > trigger_dist_sq then
            -- Too far, start following
            Wander.reset(entity)
            fsm:start_following()
         end
      end
   elseif fsm:is("following") then
      -- Priority checks (override following)
      if is_hungry then
         fsm:get_hungry()
      elseif has_target then
         -- Switching from player to enemy target
         PathFollow.clear_path(entity)
         fsm:spot_enemy()
         entity.chase_target = nearest_enemy
      elseif player then
         -- Check if we should stop following
         local dx = player.x - entity.x
         local dy = player.y - entity.y
         local dist_sq = dx * dx + dy * dy
         local stop_dist = entity.follow_stop_dist or 50
         local stop_dist_sq = stop_dist * stop_dist

         if dist_sq < stop_dist_sq then
            -- Close enough, resume wandering
            PathFollow.clear_path(entity)
            fsm:stop_following()
         end
      else
         -- Player lost/dead? Wander
         PathFollow.clear_path(entity)
         fsm:stop_following()
      end
   elseif fsm:is("seeking_food") then
      -- OPTIMIZATION: Only update emotion if not already set (debounce)
      if not entity.emotion and rnd(1) < 0.02 then
         Emotions.set(entity, "seeking_food")
      end
   elseif fsm:is("chasing") then
      -- If hungry, prioritize food
      if is_hungry then
         PathFollow.clear_path(entity)
         fsm:get_hungry()
         entity.chase_target = nil
         -- Lost target? Go back to wandering
      elseif not has_target then
         PathFollow.clear_path(entity)
         fsm:lose_target()
         entity.chase_target = nil
         -- Close enough to attack?
      elseif in_attack_range then
         fsm:reach_enemy()
         entity.chase_target = nearest_enemy
      else
         -- Update chase target to nearest enemy
         entity.chase_target = nearest_enemy
      end
   elseif fsm:is("attacking") then
      -- If hungry, prioritize food
      if is_hungry then
         fsm:get_hungry()
         entity.chase_target = nil
         -- Lost target?
      elseif not has_target then
         fsm:lose_target()
         entity.chase_target = nil
         -- Target moved out of range? Chase again
      elseif not in_attack_range then
         fsm:back_off()
         entity.chase_target = nearest_enemy
      else
         entity.chase_target = nearest_enemy
      end
   end

   -- Clear path if target entity changed (prevents following stale path to old target)
   if entity.chase_target ~= prev_target and prev_target ~= nil then
      PathFollow.clear_path(entity)
   end

   -- Execute behavior based on current state
   if fsm:is("seeking_food") then
      local range = entity.food_seek_range
      local heal = entity.food_heal_amount
      local found_food = SeekFood.update(entity, world, range, heal)

      -- If no food found and not hungry anymore, go back to wandering
      if not found_food and not is_hungry then
         fsm:eat_done()
      elseif not found_food then
         -- No food found. If we have an enemy, fight them instead of wandering aimlessly.
         if has_target then
            fsm:spot_enemy()
            entity.chase_target = nearest_enemy
         elseif player and player_cx then
            local dx = player.x - entity.x
            local dy = player.y - entity.y
            local dist_sq = dx * dx + dy * dy
            local trigger_dist = entity.follow_trigger_dist or 100
            local stop_dist = entity.follow_stop_dist or 50
            local trigger_dist_sq = trigger_dist * trigger_dist
            local stop_dist_sq = stop_dist * stop_dist

            -- Hysteresis logic
            if dist_sq > trigger_dist_sq then
               entity.seeking_follow_active = true
            elseif dist_sq < stop_dist_sq then
               entity.seeking_follow_active = false
            end

            if entity.seeking_follow_active then
               -- Too far, run towards player (hoping they lead to food)
               -- We stay in 'seeking_food' state but mimic chase behavior
               local speed_mult = entity.follow_speed_mult or 1.1
               Chase.toward(entity, player_cx, player_cy, speed_mult)
               -- OPTIMIZATION: Only set emotion if different
               if entity.emotion ~= "seeking_food" then
                  Emotions.set(entity, "seeking_food")
               end
            else
               -- Close enough, just wander
               Wander.update(entity)
               if entity.emotion ~= "seeking_food" then
                  Emotions.set(entity, "seeking_food")
               end
            end
         else
            -- No player, just wander
            Wander.update(entity)
            if entity.emotion ~= "seeking_food" then
               Emotions.set(entity, "seeking_food")
            end
         end
      end
   elseif fsm:is("chasing") then
      local target = entity.chase_target
      if target then
         local thb = HitboxUtils.get_hitbox(target)
         PathFollow.toward(entity, thb.x + thb.w / 2, thb.y + thb.h / 2, entity.chase_speed_mult, room)
      else
         PathFollow.clear_path(entity)
         Wander.update(entity)
      end
   elseif fsm:is("following") then
      if player and player_cx then
         local speed_mult = entity.follow_speed_mult or 1.1
         PathFollow.toward(entity, player_cx, player_cy, speed_mult, room)
      else
         PathFollow.clear_path(entity)
         Wander.update(entity)
      end
   elseif fsm:is("attacking") then
      local target = entity.chase_target
      if target then
         -- Attack the target
         attack_enemy(entity, target)
         -- Stop moving while attacking (knockback will push us back)
         entity.vel_x = 0
         entity.vel_y = 0
      else
         Wander.update(entity)
      end
   else -- wandering (default)
      Wander.update(entity)
   end
end

-- Module exports (AI function + target painting utilities)
return {
   update = chick_ai,
   -- Paint a target for all chicks to prioritize
   paint_target = function(enemy)
      painted_target = enemy
   end,
   -- Clear the painted target (called on room transition or target death)
   clear_target = function()
      painted_target = nil
   end,
   -- Get current painted target (for debugging)
   get_painted_target = function()
      return painted_target
   end,
}
