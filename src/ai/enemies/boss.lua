-- Green Witch boss AI profile

local machine = require("lib/lua-state-machine/statemachine")
local Emotions = require("src/systems/emotions")
local EntityUtils = require("src/utils/entity_utils")
local HitboxUtils = require("src/utils/hitbox_utils")
local Dash = require("src/ai/primitives/dash")
local DungeonManager = require("src/world").DungeonManager
local Entities = require("src/entities")

-- Phase thresholds (as fraction of max HP)
local PHASE2_THRESHOLD = 0.66
local PHASE3_THRESHOLD = 0.33

-- Behavior constants
local FLEE_ARRIVAL_THRESHOLD = 10                           -- Distance to reach flee target
local FLEE_MARGIN = 48                                      -- Margin from walls for flee target
local FLEE_GRID_OFFSET = 24                                 -- Offset from grid lines (center of tile)
local FLEE_HISTORY_THRESHOLD = 50                           -- Distance to check against history
local FLEE_HISTORY_PENALTY = 200                            -- Score penalty for revisiting positions
local FLEE_HISTORY_SIZE = 3                                 -- Max positions to remember
local FLEE_SCORE_RANDOM = 30                                -- Random factor for scoring
local FLEE_SCORE_THRESHOLD = 20                             -- Score difference for "close enough" candidates
local FLEE_SCORE_DIST_WEIGHT = 0.5                          -- Weight for distance from self
local DASH_DURATION = 40                                    -- Frames per dash
local TRANSITION_DURATION = 60                              -- Frames for phase transition animation
local SUMMON_PAUSE = 30                                     -- Pause after summoning
local SUMMON_ENEMY_TYPES = {"Skulker", "Shooter", "Dasher"} -- Random spawn types
local SUMMON_OFFSETS = {{-40, 0}, {40, 0}, {0, -40}}        -- Relative spawn positions
local SUMMON_CAP = 6                                        -- Max total minions alive
local SUMMON_BATCH_SIZE = 3                                 -- Minions to spawn per cycle

local PHASE2_SEQUENCE = {"shoot", "summon"}
local PHASE3_SEQUENCE = {"shoot", "summon", "windup"}

local PHASE3_SHOOT_DELAY = 15                                                     -- Faster fire rate in phase 3 (was 20)
local PHASE3_SHOT_COUNT = 5                                                       -- Shots per burst in phase 3
local PHASE3_SHOOT_COOLDOWN = 30                                                  -- Reduced cooldown in phase 3
local PHASE3_DASH_AIM_DURATION = 30                                               -- Aim/Windup duration before dash

local PHASE1_SHOOT_DELAY = 60                                                     -- Frames between shots (phase 1)
local PHASE1_SHOT_COUNT = 5                                                       -- Shots per burst
local PHASE2_SHOT_COUNT = 3                                                       -- Shots per burst (phase 2)

local FLEE_SPEED_MULTIPLIERS = {2, 2.5, 3}                                        -- Multipliers for Phase 1, 2, 3
local SHOOT_DELAYS = {PHASE1_SHOOT_DELAY, PHASE1_SHOOT_DELAY, PHASE3_SHOOT_DELAY} -- Shoot delays for Phase 1, 2, 3

-- Get current phase based on HP
local function get_phase(entity)
   local hp_ratio = entity.hp / entity.max_hp
   if hp_ratio > PHASE2_THRESHOLD then
      return 1
   elseif hp_ratio > PHASE3_THRESHOLD then
      return 2
   else
      return 3
   end
end

-- Shared flee behavior for phase 1 and 2
-- Returns true if reached target, false if still moving
local function do_flee(entity, player, dx, dy, dist)
   entity.shoot_dir_x = 0
   entity.shoot_dir_y = 0

   if not player then return false end

   -- Get room bounds
   local room = DungeonManager.current_room
   local bounds = room:get_inner_bounds()
   local min_x = bounds.x1 * GRID_SIZE + FLEE_GRID_OFFSET
   local max_x = bounds.x2 * GRID_SIZE - FLEE_GRID_OFFSET
   local min_y = bounds.y1 * GRID_SIZE + FLEE_GRID_OFFSET
   local max_y = bounds.y2 * GRID_SIZE - FLEE_GRID_OFFSET

   -- Calculate flee target if not set
   if not entity.flee_target_x then
      -- Initialize position history if needed
      entity.flee_history = entity.flee_history or {}

      -- Generate candidate positions (corners + edge midpoints)
      local candidates = {
         {x = min_x + FLEE_MARGIN, y = min_y + FLEE_MARGIN}, -- Top-left
         {x = max_x - FLEE_MARGIN, y = min_y + FLEE_MARGIN}, -- Top-right
         {x = min_x + FLEE_MARGIN, y = max_y - FLEE_MARGIN}, -- Bottom-left
         {x = max_x - FLEE_MARGIN, y = max_y - FLEE_MARGIN}, -- Bottom-right
         {x = (min_x + max_x) / 2, y = min_y + FLEE_MARGIN}, -- Top-center
         {x = (min_x + max_x) / 2, y = max_y - FLEE_MARGIN}, -- Bottom-center
         {x = min_x + FLEE_MARGIN, y = (min_y + max_y) / 2}, -- Left-center
         {x = max_x - FLEE_MARGIN, y = (min_y + max_y) / 2}, -- Right-center
      }

      -- Score each candidate
      local best_score = -math.huge
      local best_candidates = {}

      for _, cand in ipairs(candidates) do
         -- Distance from player (higher = better)
         local pdx = cand.x - player.x
         local pdy = cand.y - player.y
         local player_dist = sqrt(pdx * pdx + pdy * pdy)

         -- Distance from current position (higher = better)
         local cdx = cand.x - entity.x
         local cdy = cand.y - entity.y
         local current_dist = sqrt(cdx * cdx + cdy * cdy)

         -- Check if in recent history (penalty)
         local history_penalty = 0
         for _, hist in ipairs(entity.flee_history) do
            local hdx = cand.x - hist.x
            local hdy = cand.y - hist.y
            local hist_dist = sqrt(hdx * hdx + hdy * hdy)
            if hist_dist < FLEE_HISTORY_THRESHOLD then
               history_penalty += FLEE_HISTORY_PENALTY
            end
         end

         -- Score: prioritize distance from player, then from self, penalize history
         local score = player_dist + current_dist * FLEE_SCORE_DIST_WEIGHT - history_penalty + rnd(FLEE_SCORE_RANDOM)

         if score > best_score then
            best_score = score
            best_candidates = {cand}
         elseif score > best_score - FLEE_SCORE_THRESHOLD then
            -- Close enough, add to pool for randomization
            add(best_candidates, cand)
         end
      end

      -- Pick from best candidates
      local chosen = best_candidates[flr(rnd(#best_candidates)) + 1] or candidates[1]

      -- Update history (keep last 3)
      add(entity.flee_history, {x = chosen.x, y = chosen.y})
      while #entity.flee_history > FLEE_HISTORY_SIZE do
         deli(entity.flee_history, 1)
      end

      -- Clamp to room bounds
      entity.flee_target_x = mid(min_x, chosen.x, max_x)
      entity.flee_target_y = mid(min_y, chosen.y, max_y)
   end

   -- Move toward flee target
   local tx_diff = entity.flee_target_x - entity.x
   local ty_diff = entity.flee_target_y - entity.y
   local target_dist = sqrt(tx_diff * tx_diff + ty_diff * ty_diff)

   if target_dist > FLEE_ARRIVAL_THRESHOLD then
      local speed_multiplier = FLEE_SPEED_MULTIPLIERS[entity.boss_phase] or 1
      local move_speed = entity.max_speed * speed_multiplier
      entity.vel_x = (tx_diff / target_dist) * move_speed
      entity.vel_y = (ty_diff / target_dist) * move_speed
      entity.dir_x = sgn(tx_diff)
      entity.dir_y = sgn(ty_diff)
      entity.current_direction = EntityUtils.get_direction_name(tx_diff, ty_diff, entity.current_direction)
      return false
   else
      return true
   end
end

-- Shared summon logic
local function do_summon(entity, world)
   entity.vel_x = 0
   entity.vel_y = 0

   if entity.summon_pending and entity.summon_pending > 0 then
      local summoned_count = 0
      world.sys("enemy", function(enemy)
         if enemy ~= entity then -- Not the boss itself
            summoned_count += 1
         end
      end)()

      -- Spawn up to cap
      local spawned = 0
      for i = 1, SUMMON_BATCH_SIZE do
         if summoned_count + spawned < SUMMON_CAP then
            local enemy_type = SUMMON_ENEMY_TYPES[rnd(#SUMMON_ENEMY_TYPES) + 1]
            local ox, oy = SUMMON_OFFSETS[i][1], SUMMON_OFFSETS[i][2]
            Entities.spawn_enemy(world, entity.x + ox, entity.y + oy, enemy_type)
            spawned += 1
         end
      end
      entity.summon_pending = 0
   end
end

-- Shared shooting logic
local function do_shoot(entity, fsm, player, dx, dy, dist)
   -- Stop moving
   entity.vel_x = 0
   entity.vel_y = 0

   -- Aim at player
   if player and dist > 0 then
      entity.shoot_dir_x = dx / dist
      entity.shoot_dir_y = dy / dist
      entity.current_direction = EntityUtils.get_direction_name(dx, dy, entity.current_direction)
   end

   -- Determine delay based on phase
   local delay = SHOOT_DELAYS[entity.boss_phase]

   -- Shoot on cooldown
   entity.boss_timer += 1
   if entity.boss_timer >= delay then
      entity.boss_timer = 0
      entity.shots_remaining -= 1

      -- Check if shoot complete
      if entity.shots_remaining <= 0 then
         fsm:resume()
      end
   end
end

-- Initialize Boss FSM on entity
local function init_fsm(entity)
   entity.boss_phase = 1
   entity.boss_timer = 0
   entity.summon_timer = 0
   entity.dash_target_dx = 0
   entity.dash_target_dy = 0

   entity.boss_fsm = machine.create({
      initial = "phase1_flee",
      events = {
         -- Phase 1: Flee + Shoot (flee away, fire 5 shots, repeat)
         {name = "shoot",        from = "phase1_flee",                                    to = "phase1_shoot"},
         {name = "resume",       from = "phase1_shoot",                                   to = "phase1_flee"},

         -- Phase 2: Flee + Shoot (3x) + Flee + Summon (shorter/faster)
         {name = "shoot",        from = "phase2_flee",                                    to = "phase2_shoot"},
         {name = "resume",       from = "phase2_shoot",                                   to = "phase2_flee"},
         {name = "summon",       from = "phase2_flee",                                    to = "phase2_summon"},
         {name = "resume",       from = "phase2_summon",                                  to = "phase2_flee"},

         -- Phase 3: Enraged (flee → shoot → flee → summon → flee → dash loop)
         {name = "shoot",        from = "phase3_flee",                                    to = "phase3_shoot"},
         {name = "summon",       from = "phase3_flee",                                    to = "phase3_summon"},
         {name = "windup",       from = "phase3_flee",                                    to = "phase3_windup"},
         {name = "dash",         from = "phase3_windup",                                  to = "phase3_dash"},
         {name = "resume",       from = "phase3_shoot",                                   to = "phase3_flee"},
         {name = "resume",       from = "phase3_summon",                                  to = "phase3_flee"},
         {name = "resume",       from = "phase3_dash",                                    to = "phase3_flee"},

         -- Phase transitions
         {name = "to_phase2",    from = {"phase1_flee", "phase1_shoot"},                  to = "transition"},
         {name = "to_phase3",    from = {"phase2_flee", "phase2_shoot", "phase2_summon"}, to = "transition"},
         {name = "enter_phase2", from = "transition",                                     to = "phase2_flee"},
         {name = "enter_phase3", from = "transition",                                     to = "phase3_flee"},
      },
      callbacks = {
         onenterphase1_flee = function()
            -- Calculate flee target position (away from player)
            entity.flee_target_x = nil -- Will be set in update when player is known
            entity.flee_target_y = nil
         end,
         onenterphase1_shoot = function()
            entity.shots_remaining = PHASE1_SHOT_COUNT
            entity.boss_timer = 0 -- Start shooting immediately
            entity.vel_x = 0
            entity.vel_y = 0
            entity.flee_target_x = nil
         end,
         onentertransition = function()
            Emotions.set(entity, "alert")
            entity.boss_timer = TRANSITION_DURATION
            entity.vel_x = 0
            entity.vel_y = 0
         end,
         onenterphase2_flee = function()
            entity.boss_phase = 2
            entity.flee_target_x = nil                       -- Will be set in update
            entity.flee_target_y = nil
            entity.phase_step = (entity.phase_step or 0) + 1 -- Track cycle: 1=shoot, 2=summon
         end,
         onenterphase2_shoot = function()
            Emotions.set(entity, "alert")
            entity.shots_remaining = PHASE2_SHOT_COUNT
            entity.boss_timer = 0
            entity.vel_x = 0
            entity.vel_y = 0
            entity.flee_target_x = nil
            entity.flee_target_y = nil
         end,
         onenterphase2_summon = function()
            Emotions.set(entity, "alert")
            entity.boss_timer = SUMMON_PAUSE
            entity.vel_x = 0
            entity.vel_y = 0
            entity.summon_pending = SUMMON_BATCH_SIZE -- Spawn 3 enemies
            entity.phase_step = 0
         end,
         onenterphase3_flee = function()
            entity.boss_phase = 3
            entity.flee_target_x = nil
            entity.flee_target_y = nil
            entity.phase_step += 1
            entity.shoot_cooldown_duration = PHASE3_SHOOT_COOLDOWN
         end,
         onenterphase3_shoot = function()
            Emotions.set(entity, "alert")
            entity.shots_remaining = PHASE3_SHOT_COUNT
            entity.boss_timer = 0
            entity.vel_x = 0
            entity.vel_y = 0
            entity.flee_target_x = nil
            entity.flee_target_y = nil
         end,
         onenterphase3_summon = function()
            Emotions.set(entity, "alert")
            entity.boss_timer = SUMMON_PAUSE
            entity.vel_x = 0
            entity.vel_y = 0
            entity.summon_pending = SUMMON_BATCH_SIZE
         end,
         onenterphase3_windup = function()
            Emotions.set(entity, "alert")
            entity.boss_timer = PHASE3_DASH_AIM_DURATION
            entity.vel_x = 0
            entity.vel_y = 0
            entity.aim_locked = false
            entity.flee_target_x = nil
            entity.flee_target_y = nil
         end,
         onenterphase3_dash = function()
            entity.boss_timer = DASH_DURATION
            entity.phase_step = 0
         end,
      }
   })
end

-- Main AI update for Green Witch boss
local function boss_ai(entity, player)
   if not entity.boss_fsm then
      init_fsm(entity)
   end

   local fsm = entity.boss_fsm

   -- Calculate distance and direction to player
   local dist = math.huge
   local dx, dy = 0, 0
   if player then
      local hb_p = HitboxUtils.get_hitbox(player)
      local hb_e = HitboxUtils.get_hitbox(entity)
      dx = (hb_p.x + hb_p.w / 2) - (hb_e.x + hb_e.w / 2)
      dy = (hb_p.y + hb_p.h / 2) - (hb_e.y + hb_e.h / 2)
      dist = sqrt(dx * dx + dy * dy)
   end

   -- Check for phase transitions
   local current_phase = get_phase(entity)
   if current_phase == 2 and entity.boss_phase == 1 then
      if fsm:to_phase2() then
         Log.info("Boss phase transition: 1 -> 2 (HP: "..entity.hp.."/"..entity.max_hp..")")
         return
      end
   elseif current_phase == 3 and entity.boss_phase == 2 then
      if fsm:to_phase3() then
         Log.info("Boss phase transition: 2 -> 3 (HP: "..entity.hp.."/"..entity.max_hp..")")
         return
      end
   end

   -- State-specific behavior
   if fsm:is("phase1_flee") then
      if do_flee(entity, player, dx, dy, dist) then
         fsm:shoot()
      end
   elseif fsm:is("phase1_shoot") then
      do_shoot(entity, fsm, player, dx, dy, dist)
   elseif fsm:is("transition") then
      -- Invulnerable transition animation
      entity.vel_x = 0
      entity.vel_y = 0
      entity.boss_timer -= 1

      if entity.boss_timer <= 0 then
         if entity.boss_phase == 1 then
            fsm:enter_phase2()
         else
            fsm:enter_phase3()
         end
      end
   elseif fsm:is("phase2_flee") then
      if do_flee(entity, player, dx, dy, dist) then
         local step_idx = (entity.phase_step or 1) % #PHASE2_SEQUENCE
         if step_idx == 0 then step_idx = #PHASE2_SEQUENCE end

         local event = PHASE2_SEQUENCE[step_idx]
         fsm[event](fsm)
      end
   elseif fsm:is("phase2_shoot") then
      do_shoot(entity, fsm, player, dx, dy, dist)
   elseif fsm:is("phase2_summon") then
      -- Spawn enemies around witch (capped at 6 total summoned enemies)
      do_summon(entity, world)

      entity.boss_timer -= 1
      if entity.boss_timer <= 0 then
         fsm:resume()
      end
   elseif fsm:is("phase3_flee") then
      if do_flee(entity, player, dx, dy, dist) then
         -- Cycle: shoot, summon, windup, repeat
         local step_idx = (entity.phase_step or 1) % #PHASE3_SEQUENCE
         if step_idx == 0 then step_idx = #PHASE3_SEQUENCE end

         local event = PHASE3_SEQUENCE[step_idx]
         fsm[event](fsm)
      end
   elseif fsm:is("phase3_shoot") then
      do_shoot(entity, fsm, player, dx, dy, dist)
   elseif fsm:is("phase3_summon") then
      -- Spawn enemies around witch (same cap as phase 2)
      do_summon(entity, world)

      entity.boss_timer -= 1
      if entity.boss_timer <= 0 then
         fsm:resume()
      end
   elseif fsm:is("phase3_windup") then
      -- Brief pause to aim at player before dashing
      if Dash.windup(entity, dx, dy, dist, entity.aim_locked) then
         entity.aim_locked = true
      end

      entity.boss_timer -= 1
      if entity.boss_timer <= 0 then
         fsm:dash()
      end
   elseif fsm:is("phase3_dash") then
      -- Move using shared dash logic
      entity.hit_wall = Dash.update(entity)
      entity.dir_x = sgn(entity.vel_x) -- Update facing to match movement
      entity.dir_y = sgn(entity.vel_y)

      entity.boss_timer -= 1
      if entity.boss_timer <= 0 or entity.hit_wall then
         entity.hit_wall = false
         fsm:resume()
      end
   end
end

return boss_ai
