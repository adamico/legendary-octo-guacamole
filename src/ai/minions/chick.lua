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

-- Configuration: How long to try reaching an unreachable target before giving up
local MAX_CHASE_STUCK_FRAMES = 60      -- ~1 second at 60fps
local UNREACHABLE_BLACKLIST_TIME = 5.0 -- Seconds to blacklist an unreachable enemy

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
--- Skips enemies that are temporarily blacklisted as unreachable
--- @param entity table - The chick
--- @param world table - ECS world
--- @param room_bounds table|nil - Pre-fetched room bounds
--- @param player table|nil - Player (for vision bonus)
--- @return table|nil, number - Nearest enemy and distance squared (or nil if none)
local function find_nearest_enemy(entity, world, room_bounds, player)
   -- Apply player's vision bonus if available
   local vision_range = entity.vision_range + ((player and player.minion_vision_bonus) or 0)
   local vision_range_sq = vision_range * vision_range
   local nearest_enemy = nil
   local nearest_dist_sq = vision_range_sq

   local ex, ey = entity.x, entity.y

   -- Initialize blacklist if needed
   entity.unreachable_blacklist = entity.unreachable_blacklist or {}

   -- Clean up expired blacklist entries
   local now = t()
   for enemy, expire_time in pairs(entity.unreachable_blacklist) do
      if expire_time < now then
         entity.unreachable_blacklist[enemy] = nil
      end
   end

   -- Target painting: If painted target exists and is alive, prioritize it
   if painted_target and painted_target.hp and painted_target.hp > 0 then
      -- Don't skip painted target even if blacklisted (player specifically marked it)
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
      -- Skip blacklisted enemies (temporarily unreachable)
      if entity.unreachable_blacklist[enemy] then
         return
      end

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
--- @param player table|nil - The player (for bonus damage)
local function attack_enemy(entity, target, player)
   -- Check attack cooldown
   if entity.attack_timer and entity.attack_timer > 0 then
      return false -- Still on cooldown
   end

   -- Deal damage (base + player bonus)
   local damage = entity.attack_damage
   if player and player.minion_damage_bonus then
      damage = damage + player.minion_damage_bonus
   end
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

   -- Reset attack cooldown (apply player's reduction bonus if available)
   local base_cooldown = entity.attack_cooldown
   local reduction = (player and player.minion_cooldown_reduction) or 0
   entity.attack_timer = math.max(5, base_cooldown - reduction)

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

   -- OPTIMIZATION: Cache player reference early (needed for Face-Hugger and bonuses)
   local player = nil
   world.sys("player", function(p) player = p end)()

   -- One-time bonus application: Add minion HP bonus when first spawned
   if not entity.bonuses_applied and player then
      local hp_bonus = player.minion_hp_bonus or 0
      if hp_bonus > 0 then
         entity.max_hp = (entity.max_hp or 20) + hp_bonus
         entity.hp = (entity.hp or entity.max_hp) + hp_bonus
      end
      entity.bonuses_applied = true
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
            attack_enemy(entity, target, player)
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


   -- OPTIMIZATION: Cache player hitbox center if player exists (reused multiple times)
   local player_cx, player_cy
   if player then
      local phb = HitboxUtils.get_hitbox(player)
      player_cx = phb.x + phb.w / 2
      player_cy = phb.y + phb.h / 2
   end

   -- Gather perception data
   local is_hungry = entity.hp < (entity.max_hp or 20) / 2
   local nearest_enemy, enemy_dist_sq = find_nearest_enemy(entity, world, room_bounds, player)
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
         local tx, ty = thb.x + thb.w / 2, thb.y + thb.h / 2

         -- Get entity center for distance/LOS checks
         local hb = HitboxUtils.get_hitbox(entity)
         local ex, ey = hb.x + hb.w / 2, hb.y + hb.h / 2
         local chase_dx, chase_dy = tx - ex, ty - ey
         local chase_dist = sqrt(chase_dx * chase_dx + chase_dy * chase_dy)

         -- For close targets with clear line-of-sight, use direct chase (no pathfinding overhead)
         -- This also fixes the "no path" freeze when target is very close
         local DIRECT_CHASE_DIST = 48
         local has_los = PathFollow.has_line_of_sight(ex, ey, tx, ty, room)

         if chase_dist < DIRECT_CHASE_DIST and has_los then
            -- Close enough with clear path - use direct Chase
            Chase.toward(entity, tx, ty, entity.chase_speed_mult)
            entity.chase_stuck_frames = 0
         else
            -- Far away or blocked - use A* pathfinding
            PathFollow.toward(entity, tx, ty, entity.chase_speed_mult, room)

            -- Stuck detection: if no valid path for too long, abandon this target
            local has_path = PathFollow.has_path(entity)
            if not has_path then
               entity.chase_stuck_frames = (entity.chase_stuck_frames or 0) + 1
               -- Can't reach enemy - try to return to player instead of wandering
               if player and player_cx then
                  PathFollow.toward(entity, player_cx, player_cy, entity.chase_speed_mult, room)
               else
                  Wander.update(entity)
               end
               if entity.chase_stuck_frames >= MAX_CHASE_STUCK_FRAMES then
                  -- Can't reach target, give up and return to player
                  -- Clear blacklist so chick can retarget from new position
                  entity.unreachable_blacklist = {}
                  PathFollow.clear_path(entity)
                  fsm:lose_target()
                  entity.chase_target = nil
                  entity.chase_stuck_frames = 0
               end
            else
               entity.chase_stuck_frames = 0 -- Reset counter when path exists
            end
         end
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
         attack_enemy(entity, target, player)
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

-- Track active chicks for blacklist clearing (set during update)
local active_chicks = {}

-- Module exports (AI function + target painting utilities)
return {
   update = function(entity, world)
      -- Track this chick for blacklist clearing
      active_chicks[entity] = true
      return chick_ai(entity, world)
   end,
   -- Paint a target for all chicks to prioritize
   -- Also clears the enemy from all chick blacklists so they retry reaching it
   paint_target = function(enemy)
      -- Clear outline from previous target
      if painted_target and painted_target ~= enemy then
         painted_target.outline_color = nil
      end
      painted_target = enemy
      -- Add orange outline to show painted status
      if enemy then
         enemy.outline_color = 9 -- Orange/yolk color
         -- Clear this enemy from all chick blacklists
         for chick, _ in pairs(active_chicks) do
            if chick.unreachable_blacklist then
               chick.unreachable_blacklist[enemy] = nil
            end
         end
      end
   end,
   -- Clear the painted target (called on room transition or target death)
   clear_target = function()
      if painted_target then
         painted_target.outline_color = nil
      end
      painted_target = nil
   end,
   -- Get current painted target (for debugging)
   get_painted_target = function()
      return painted_target
   end,
   -- Clear active chicks tracking (call on room transition)
   clear_active_chicks = function()
      active_chicks = {}
   end,
}
