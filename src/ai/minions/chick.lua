-- Chick AI behavior
-- FSM: wandering <-> seeking_food <-> chasing <-> attacking
-- Priority: hungry > enemy in range > wander

local machine = require("lib/lua-state-machine/statemachine")
local Wander = require("src/ai/primitives/wander")
local Chase = require("src/ai/primitives/chase")
local SeekFood = require("src/ai/primitives/seek_food")
local FloatingText = require("src/systems/floating_text")

local function init_fsm(entity)
   entity.chick_fsm = machine.create({
      initial = "wandering",
      events = {
         {name = "get_hungry",  from = {"wandering", "chasing", "attacking"}, to = "seeking_food"},
         {name = "spot_enemy",  from = {"wandering", "seeking_food"},         to = "chasing"},
         {name = "reach_enemy", from = "chasing",                             to = "attacking"},
         {name = "lose_target", from = {"chasing", "attacking"},              to = "wandering"},
         {name = "back_off",    from = "attacking",                           to = "chasing"},
         {name = "eat_done",    from = "seeking_food",                        to = "wandering"},
      },
      callbacks = {}
   })
end

--- Find nearest enemy within vision range
--- @param entity table - The chick
--- @param world table - ECS world
--- @return table|nil, number - Nearest enemy and distance (or nil if none)
local function find_nearest_enemy(entity, world)
   local vision_range = entity.vision_range
   local nearest_enemy = nil
   local nearest_dist_sq = vision_range * vision_range

   world.sys("enemy", function(enemy)
      local dx = enemy.x - entity.x
      local dy = enemy.y - entity.y
      local dist_sq = dx * dx + dy * dy
      if dist_sq < nearest_dist_sq then
         nearest_dist_sq = dist_sq
         nearest_enemy = enemy
      end
   end)()

   return nearest_enemy, sqrt(nearest_dist_sq)
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
   local len = sqrt(dx * dx + dy * dy)
   if len > 0 then
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

   local fsm = entity.chick_fsm

   -- Gather perception data
   local is_hungry = entity.hp < (entity.max_hp or 20) / 2
   local nearest_enemy, enemy_dist = find_nearest_enemy(entity, world)
   local has_target = nearest_enemy ~= nil
   local in_attack_range = has_target and enemy_dist < entity.attack_range

   -- State transitions based on priority: hungry > attack > chase > wander
   if fsm:is("wandering") then
      if is_hungry and fsm:can("get_hungry") then
         fsm:get_hungry()
      elseif has_target and fsm:can("spot_enemy") then
         fsm:spot_enemy()
         entity.chase_target = nearest_enemy
      end
   elseif fsm:is("seeking_food") then
      -- If an enemy gets close, switch to chase (defend self)
      if has_target and fsm:can("spot_enemy") then
         fsm:spot_enemy()
         entity.chase_target = nearest_enemy
      end
   elseif fsm:is("chasing") then
      -- If hungry, prioritize food
      if is_hungry and fsm:can("get_hungry") then
         fsm:get_hungry()
         entity.chase_target = nil
         -- Lost target? Go back to wandering
      elseif not has_target and fsm:can("lose_target") then
         fsm:lose_target()
         entity.chase_target = nil
         -- Close enough to attack?
      elseif in_attack_range and fsm:can("reach_enemy") then
         fsm:reach_enemy()
         entity.chase_target = nearest_enemy
      else
         -- Update chase target to nearest enemy
         entity.chase_target = nearest_enemy
      end
   elseif fsm:is("attacking") then
      -- If hungry, prioritize food
      if is_hungry and fsm:can("get_hungry") then
         fsm:get_hungry()
         entity.chase_target = nil
         -- Lost target?
      elseif not has_target and fsm:can("lose_target") then
         fsm:lose_target()
         entity.chase_target = nil
         -- Target moved out of range? Chase again
      elseif not in_attack_range and fsm:can("back_off") then
         fsm:back_off()
         entity.chase_target = nearest_enemy
      else
         entity.chase_target = nearest_enemy
      end
   end

   -- Execute behavior based on current state
   if fsm:is("seeking_food") then
      local range = entity.food_seek_range
      local heal = entity.food_heal_amount
      local found_food = SeekFood.update(entity, world, range, heal)

      -- If no food found and not hungry anymore, go back to wandering
      if not found_food and not is_hungry and fsm:can("eat_done") then
         fsm:eat_done()
      elseif not found_food then
         -- No food nearby, wander while looking
         Wander.update(entity)
      end
   elseif fsm:is("chasing") then
      local target = entity.chase_target
      if target then
         Chase.toward(entity, target.x, target.y, entity.chase_speed_mult)
      else
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

return chick_ai
