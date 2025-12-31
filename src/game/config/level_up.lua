-- Level Up Bonus Definitions
-- Each bonus has: category, name, description, and an apply function
local GameConstants = require("src/game/game_config")

local LevelUpConfig = {}

-- Helper to create bonus entries
local function bonus(category, name, description, apply_fn)
   return {category = category, name = name, description = description, apply = apply_fn}
end

-- Player stat bonuses
LevelUpConfig.Player = {
   bonus("Player Stats", "Vitality", "Max HP +20 & Heal", function(p)
      p.max_hp = p.max_hp + 20
      p.hp = math.min(p.hp + 20, p.max_hp)
   end),
   bonus("Player Stats", "Swiftness", "Speed +0.2", function(p)
      p.max_speed = p.max_speed + 0.2
   end),
   bonus("Player Stats", "Hardened Shell", "Damage -10%", function(p)
      p.damage_reduction = (p.damage_reduction or 1.0) * 0.9
   end),
   bonus("Player Stats", "Vampirism", "Lifesteal +10%", function(p)
      p.vampiric_heal = (p.vampiric_heal or 0.3) + 0.1
   end),
   bonus("Player Stats", "Iron Skin", "Invuln +15 fr", function(p)
      p.invulnerability_duration = (p.invulnerability_duration or 120) + 15
   end),
   bonus("Player Stats", "Brawler", "Melee Dmg +5", function(p)
      p.melee_bonus_damage = (p.melee_bonus_damage or 0) + 5
   end),
}

-- Egg projectile bonuses
LevelUpConfig.Egg = {
   bonus("Egg Stats", "Heavy Shell", "Impact Dmg +2", function(p)
      p.impact_damage = (p.impact_damage or GameConstants.Player.dud_damage) + 2
      p.drain_damage = (p.drain_damage or GameConstants.Player.leech_damage) + 2
   end),
   bonus("Egg Stats", "Rapid Fire", "Fire Rate +25%", function(p)
      p.fire_rate = math.max(5, p.fire_rate - 3)
      p.shoot_cooldown_duration = p.fire_rate
   end),
   bonus("Egg Stats", "Long Shot", "Range +40", function(p)
      p.range = p.range + 40
   end),
   bonus("Egg Stats", "Efficiency", "Cost -1%", function(p)
      p.max_hp_to_shot_cost_ratio = math.max(0.01, p.max_hp_to_shot_cost_ratio - 0.01)
   end),
   bonus("Egg Stats", "Sticky Gloop", "Slow +0.5s", function(p)
      p.egg_slow_duration = (p.egg_slow_duration or 60) + 30
      p.egg_slow_factor = math.max(0.1, (p.egg_slow_factor or 0.5) - 0.1)
   end),
}

-- Chick minion bonuses (modifiers stored on player, read by chick AI)
LevelUpConfig.Chick = {
   bonus("Chick Stats", "Alpha Chick", "Chick Dmg +1", function(p)
      p.minion_damage_bonus = (p.minion_damage_bonus or 0) + 1
   end),
   bonus("Chick Stats", "Hyperactive", "Chick Atk Spd +", function(p)
      p.minion_cooldown_reduction = (p.minion_cooldown_reduction or 0) + 5
   end),
   bonus("Chick Stats", "Hunter Sight", "Vision +32", function(p)
      p.minion_vision_bonus = (p.minion_vision_bonus or 0) + 32
   end),
   bonus("Chick Stats", "Durable", "Chick HP +10", function(p)
      p.minion_hp_bonus = (p.minion_hp_bonus or 0) + 10
   end),
}

return LevelUpConfig
