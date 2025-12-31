# RPG Level Up

## Mechanics

## Exp gaining

When a monster dies, it drops DNA strands (experience in the RPG sense) that can be used to level up the player's stats. The DNA strands can also generate in chests (1% chance per chest roll) and in locked chests (5% per chest roll).

## Leveling effects

 When the player levels up, it is presented with a choice of 3 upgrade options:

- one option is linked to a player related stat (health, move speed, etc.)
  - max_health
  - max_speed
  - damage_reduction

- one option is linked to an egg projectile related stat
  - shot_speed
  - range
  - max_hp_to_shot_cost_ratio
  - fire_rate
  - base_knockback
  - dud_damage
  - egg_stun_duration
  - egg_slow_duration
  - egg_slow_factor (these 3 should be probably linked)

- one option is linked to a stat of the chick minions

## XP scaling

Different enemy types drop different amounts of XP. XP requirements should increase per level with a curve that is steeper for higher levels. The first 10 levels must be easy to reach so linear XP scaling is used.

## Player Level

Player Level resets each run (roguelike style).

## UI

The XP bar should be visible at the bottom of the screen, overlapping with the bottom wall of the room.
