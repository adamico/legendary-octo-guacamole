# TODO

## Next

- remove the directional line of sight of the dasher enemies, make it a circle with a radius equal to their current vision value
- add powerups  [BRAINSTORM]
- add key using mechanics [BRAINSTORM]
- add chests (locked and unlocked) as room features [BRAINSTORM]
- add locked treasure room for powerups [BRAINSTORM]
- add shop room with items [BRAINSTORM]
- don't show enemies spawning spots when transitioning from room to room [BRAINSTORM]

## Bugs

No known bugs at this time.

## Architecture

- add rendering.md in docs/architecture/ [DONE]

- implement movement mechanics [BRAINSTORM]
  - [ ] Dodge Roll / Dash (invulnerability frames or vaulting)
  - [ ] Room-Clear Rush (temp speed boost after clearing room)
  - [ ] Passive Speed Momentum (speed increases when walking straight)
- implement environmental hazards [BRAINSTORM]
  - [ ] Ice Tiles (sliding physics)
  - [ ] Conveyor Belts (push entities)
  - [ ] Spike Traps (retracting spikes)
  - [ ] Secret Walls (bombable shortcuts)

## Combat & Mechanics

- allow showing the fullmap with a keyboard shortcut [BRAINSTORM]

## AI & Enemies

- add warnings for enemy attacks (dash, shoot) [BRAINSTORM]
- add simple pathfinding for enemies [BRAINSTORM]
- make skull harder to kill (faster) [BRAINSTORM]

## World & Level Design

- add room floor patterns to avoid having floors that are too random [BRAINSTORM]
- add boss room with special enemy [BRAINSTORM]
- solid map tiles should have configurable y collision level [BRAINSTORM]
- add secret rooms [BRAINSTORM]

## Items & Powerups

- expand health recovery mechanics [BRAINSTORM]
  - [ ] Skill-based: Perfect Dodge (restore HP on last-second dodge), Multi-Kill bonus
  - [ ] Room-based: Speed Clear bonus, No-Hit bonus
  - [ ] Risk/Reward: Skull Conversion (killing pressure skull drops big heart), Low-HP desperation buff
  - [ ] Mechanical: Boomerang shots (recover HP on catch), Magnetic Hearts

## Future Roadmap: Pizza Theme Overhaul

- [ ] **Currency**: "The Nickel Pizak" (coins) or "Slices" (spendable health)
- [ ] **Keys**: "Dough Knots" or "Pizza Cutter Handles"
- [ ] **Bombs**: "Dough-mbs" (sticky dough explosion) or "Spicy Meatballs" (fire trail)
- [ ] **Ammo Types (Hearts)**:
  - Red Slice (Standard)
  - Garlic Clove (Stink Aura/DoT)
  - Anchovy Heart (Curse: 2x Dmg, Double Hit Penalty)
  - Pineapple Slice (Ghost/Shield Ammo)
- [ ] **Consumables**: "Menu Extras" (Cold Pizza=Heal+Slow, Marinara Dip=Dmg Boost)
- [ ] **Breakables**: Pizza Boxes, Flour Sacks (Smoke Screen), Olive Oil Bottles (Slippery Tiles)

## Balance Tuning (Research)

- [ ] Evaluate Economy: Net HP cost per room (currently negative, requires skill/regen)
- [ ] Playtest: Should weak enemies die in 1 shot vs 2 shots?
- [ ] Playtest: Drop rate (50% vs 100%) for enemy kills
- [ ] Playtest: Contact damage vs Shot cost (currently 10 vs 20)

## Visuals & Juice

- add a bouncing effect for the pickup items [BRAINSTORM]
- separate upper and lower body animations [BRAINSTORM]
- improve the visuals of the aiming line [BRAINSTORM]
- decorate the starting screen with game instructions [BRAINSTORM]
- improve the title screen [BRAINSTORM]
- improve the game over screen [BRAINSTORM]
- add a credits screen [BRAINSTORM]
- add a special screen or player effect when shooting an egg which damages the player (to show the cost of the shot) [BRAINSTORM]

## Audio

- add music [BRAINSTORM]
- add sound effects [BRAINSTORM]

## Powerup ideas

Projectile effects:

1. multi-shot: bonus projectile with 75% the base cost
2. piercing-shot: projectiles hit and pass through one enemy
3. exploding-shot: projectiles impact generate 3x3 explosion (which can harm like the bomb generated effect)
4. fast-shot: increase projectile speed by 25%
5. long-shot: increase projectile range
6. cheap-shot: decrease projectile cost by 25%
7. vampiric-shot: projectile hit heals 25% of the projectile total damage
8. power-shot: projectile hit gains 25% bonus damage

Movement effects:

1. speed-walk: 25% bonus movement speed
2. toxic-walk: generates damage inflicting area on tiles walked on
3. heal-walk: movement heals 5% health per second
4. heal-stay: standing still for 1 second triggers heal regen at 5% health per second

Health effects:

1. regen-overheal: each point of overheal is consumed to bestow 5% health gained per second
2. shield-overheal: each point of overheal turns into temporary health (shield)
3. damage-overheal: each point of overheal gives 1% bonus damage

Defense effects:

1. bulwark: 5% damage reduction
