# Health Recovery System Ideas

Brainstormed improvements to the health recovery system beyond the current three methods:

1. Picking up projectiles which collided with solid tiles
2. Picking up hearts dropped by enemies
3. Health regen when out of combat for a couple of seconds

---

## Skill-Based Recovery

- **Perfect Dodge Recovery** - Gain small HP boost (5-10) for dodging attacks at the last moment (i-frame trigger)
- **Multi-Kill Bonus** - Killing 2+ enemies within 1-2 seconds drops a larger heart
- **Combo Kills** - Chain kills without missing a shot grant escalating HP recovery
- **Wall Trick Shots** - Projectiles hitting walls near enemies convert to pickups with bonus value

## Room/Progression-Based Recovery

- **Room Clear Bonus** - Small guaranteed HP reward for clearing a room (10-20 HP)
- **Speed Clear Bonus** - Extra HP if room cleared under a time limit
- **No-Hit Bonus** - Bonus heart spawn if room cleared without taking damage
- **Healing Fountains** - Treasure rooms could contain fountains that heal while standing in them

## Risk/Reward Recovery

- **Skull Conversion** - Killing the pressure skull drops a large heart (makes staying risky but rewarding)
- **Low-HP Mode** - Below 1 segment, `recovery_percent` increases (desperate comeback mechanic)
- **Overkill Drops** - Dealing more damage than needed to kill increases drop chance/size
- **Sacrifice Altar** - Spend health to activate, then heal more later (banking mechanic)

## Enemy-Related Recovery

- **Vampiric Hits** - Certain enemy types heal on kill (already planned as powerup in DESIGN.md)
- **Boss Phase Hearts** - Bosses drop guaranteed healing during phases or on death
- **Stun Recovery** - Stunned enemies heal you if killed while stunned (synergy with Dasher)

## Environmental Recovery

- **Healing Tiles** - Rare floor tiles that slowly regenerate HP while standing
- **Destructible Objects** - Break pots/barrels for small chance of heart drops
- **Secret Rooms** - Hidden rooms with heart containers or healing pools

## Mechanical Twists

- **Returning Projectiles** - Boomerang-style shots recover small amount on catch
- **Chain Pickups** - Collecting pickups quickly gives bonus recovery (snowball effect)
- **Magnetic Hearts** - Rare hearts that attract nearby pickups, consolidating recovery
- **Overflow Conversion** - At max HP, collecting hearts banks them (ties into `overflow_hp` system)

---

## Priority Recommendations

Ideas that align best with the core "health as ammo" design philosophy:

1. **Skill-based** (#1-4) - Rewards precision play
2. **Risk/Reward** (especially Skull Conversion, Low-HP Mode) - Creates tension
3. **Overflow Conversion** - Expands existing `overflow_hp` architecture
