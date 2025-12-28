# TODO

## Architecture

- update architecture.md with current codebase structure [PENDING]
- add more sub documents to help the agent understand the codebase:
  - procedural generation [PENDING]

## Combat & Mechanics

- change the way the player controls the shooting action: pressing the button shows a trajectory line, releasing it shoots the laser in the direction of the line [BRAINSTORM]
- allow punching the skull to death [BRAINSTORM]
- maybe add a mechanic to react to the player being hurt (blood lost, etc.) [BRAINSTORM]
- the player must not die when firing the last segment of health, it should be put at 1 hp [PENDING]
- when player projectiles hit destructible objects they must spawn projectile pickups [PENDING]

## AI & Enemies

- skulls should die after they collide with the player [BRAINSTORM]
- skulls spawned when the room is not cleared should not prevent the room from being cleared [BRAINSTORM]
- add warnings for enemy attacks (dash, shoot) [BRAINSTORM]

## World & Level Design

- add room carvings patterns similar to the ones in The Binding of Isaac: Rebirth [BRAINSTORM]
- add room features system to allow creating solid obstacles which impede entities movement, block line of sight, etc. [BRAINSTORM]
- add room floor patterns to avoid having floors that are too random [BRAINSTORM]
- add locked treasure room for powerups [BRAINSTORM]
- add shop room with items [BRAINSTORM]
- add boss room with special enemy [BRAINSTORM]
- solid map tiles should have configurable y sorted collision boxes [BRAINSTORM]
- remove door rotation [BRAINSTORM]
- feature patterns should be symmetrical in both directions [PENDING]

## Items & Powerups

- add more pickup items (bombs, keys, coins) [BRAINSTORM]
- add powerups (see PICKUP_SYSTEM.md) [BRAINSTORM]

## Visuals & Juice

- add a bouncing effect for the pickup items [BRAINSTORM]
- separate upper and lower body animations [BRAINSTORM]
