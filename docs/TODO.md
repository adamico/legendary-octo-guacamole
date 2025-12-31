# TODO

## Next

- add levelup choice modal screen [BRAINSTORM]
- add genetic mutation system (powerups that modify the mechanics) [BRAINSTORM]
- add locked treasure room for powerups [BRAINSTORM]
- add shop room with items [BRAINSTORM]
- add boss room with special enemy [BRAINSTORM]

## Bugs

## Architecture

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

## UI

- allow showing the fullmap with a keyboard shortcut [BRAINSTORM]

## AI & Enemies

- make skulls faster (faster) [BRAINSTORM]

## World & Level Design

- add room floor patterns to avoid having floors that are too random [BRAINSTORM]
- solid map tiles should have configurable y collision level [BRAINSTORM]
- add secret rooms [BRAINSTORM]

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
- chest drops should have a popup animation [BRAINSTORM]
- add warnings for enemy attacks (dash, shoot) [BRAINSTORM]

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
