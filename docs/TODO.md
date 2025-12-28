# TODO

## Architecture

- decouple animation fsm from lifecycle [BRAINSTORM]
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

## AI & Enemies

- add warnings for enemy attacks (dash, shoot) [BRAINSTORM]

## World & Level Design

- add room floor patterns to avoid having floors that are too random [BRAINSTORM]
- add locked treasure room for powerups [BRAINSTORM]
- add shop room with items [BRAINSTORM]
- add boss room with special enemy [BRAINSTORM]
- solid map tiles should have configurable y sorted collision boxes [BRAINSTORM]

## Items & Powerups

- add more pickup items (bombs, keys, coins) [BRAINSTORM]
  - [ ] Implement Keys (Bronze Key, Key Ring) for locked treasure rooms
  - [ ] Implement Coins (Gold Coin, Gem, Trophy) for shops and interactions
  - [ ] Implement Bombs (Standard Bomb) for destructible walls and combat
  - [ ] Implement Speed/Damage Boost pickups (Star, Lightning)
- add powerups (see PICKUP_SYSTEM.md) [BRAINSTORM]
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
- add UI elements (bombs, keys, coins, powerups) [BRAINSTORM]

## Audio

- add music [BRAINSTORM]
- add sound effects [BRAINSTORM]
