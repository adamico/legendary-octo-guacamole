# Game Design Document: Health-Attack Linked Dungeon Crawler

## Core Concept

A **Binding of Isaac-style dungeon crawler** where **health is your ammunition**. Every shot costs life, but precision and collection allow you to reclaim it. The central design question: *How aggressively can you play before you run out of life to spend?*

## Current State (MVP)

### Core Loop
1. **Shoot** → Lose HP (20 per shot)
2. **Projectile hits wall** → Becomes pickup
3. **Collect pickup** → Recover HP (16, or 80% of cost)
4. **Passive regen** → Slow HP recovery when not shooting (5 HP/sec after 3s delay)

### Player Stats (Base Values)
```lua
max_hp = 100          -- 5 shots at full health
shot_cost = 20        -- HP per projectile fired
recovery_percent = 0.8 -- 80% return on pickups
regen_rate = 5        -- HP per second (currently enabled for testing)
regen_delay = 3.0     -- Seconds without shooting before regen kicks in
overflow_hp = 0       -- Banked HP above max_hp for future mechanics
```

### Visual Design: Three-State Health Bar

The health bar uses **color-coded segments** to clearly communicate available shots:

- 🟢 **GREEN**: Full segment (20 HP) = Shot ready
- 🟠 **ORANGE**: Partial segment (1-19 HP) = Charging toward shot
- 🔴 **RED**: Empty segment (0 HP) = No ammo

**Key Properties:**
- Dynamically scales with `shot_cost` and `max_hp` (supports any stat modification)
- Each segment represents exactly one shot
- Fractional HP shown as orange "charging" progress

**Example:**
```
100 HP: [🟢🟢🟢🟢🟢] = 5 shots ready
 96 HP: [🟢🟢🟢🟢🟠] = 4 shots + 80% toward 5th (after collecting 1 pickup)
 80 HP: [🟢🟢🟢🟢🔴] = 4 shots (after firing once)
```

## Architecture for Roguelike Elements

### 1. Stat Scaling System

All core mechanics use **player-owned stats** rather than hardcoded values:

```lua
-- Flexible stat-based calculations
segments = ceil(entity.max_hp / entity.shot_cost)
segment_hp = clamp(entity.hp - (i * entity.shot_cost), 0, entity.shot_cost)
recovery = projectile.shot_cost * projectile.recovery_percent
```

**This enables:**
- Powerups that modify costs: `"Efficient Shot": shot_cost = 15`
- Max HP increases: `"Heart Container": max_hp = 120` → Displays 6 segments
- Recovery modifiers: `"Magnet Shard": recovery_percent = 1.0` → Full refund

### 2. Overflow HP Banking

HP exceeding `max_hp` is stored in `overflow_hp` rather than discarded:

```lua
if player.hp > player.max_hp then
   player.overflow_hp += (player.hp - player.max_hp)
   player.hp = player.max_hp
end
```

**Potential Uses:**
- **Shields**: Convert overflow to temporary barrier
- **Burst Heal**: Spend overflow to raise max_hp temporarily
- **Power Shots**: Consume overflow for enhanced projectiles
- **Risk/Reward**: Visible resource for "greedy" play

### 3. Projectile Snapshot System

Projectiles carry their **firing stats** rather than referencing global values:

```lua
projectile = {
   shot_cost = shooter.shot_cost,           -- Cost at time of firing
   recovery_percent = shooter.recovery_percent  -- Recovery at time of firing
}
```

**This enables:**
- Mid-flight stat changes (pickup a powerup while shots are active)
- Different ammo types: `projectile.shot_cost = 30` for "Heavy Shot"
- Per-shot modifiers: Critical hits, enchantments, curses

### 4. Regen Infrastructure

Health regen is **timer-based with configurable parameters**:

```lua
-- Tracks time without firing
entity.time_since_shot = 0  

-- Conditional activation
if time_since_shot >= regen_delay and regen_rate > 0 then
   hp += regen_rate / 60
end
```

**Powerup Examples:**
- `"Meditation"`: `regen_delay = 0.5` (faster activation)
- `"Troll Blood"`: `regen_rate = 10` (double speed)
- `"Berserker"`: `regen_rate = 0` (disable regen, increase damage)
- `"Combat Medic"`: Regen only when no enemies nearby

### 5. Entity Type-Based Collision

Collision handlers use **entity types** for flexible interactions:

```lua
Systems.CollisionHandlers.entity["Player,HealthPickup"] = function(player, pickup)
   -- Custom pickup logic
end

Systems.CollisionHandlers.map["Projectile"] = function(projectile, x, y)
   -- Wall impact behavior
end
```

**This supports:**
- Multiple projectile types with different wall behaviors
- Enemy-specific interactions
- Environmental hazards (lava, ice, etc.)
- Status effect triggers

## Future Design Considerations

### Powerup Categories

**Stat Modifiers** (Passive)
- Max HP changes
- Shot cost reduction/increase
- Recovery efficiency
- Regen rate/delay

**Proc/On-Hit Effects** (Active)
- "Vampiric": Projectiles heal on enemy hit
- "Explosive": Projectiles create AoE on wall impact
- "Piercing": Projectiles pass through enemies (reduce recovery?)
- "Boomerang": Projectiles return after hitting wall

**Conditional Modifiers** (Situational)
- "Glass Cannon": Lower max HP, higher damage
- "Desperate": Bonus recovery when below 40 HP
- "Combo": Increased recovery for consecutive pickups
- "Risk Taker": Overflow HP increases damage

### Class System Ideas

**Berserker** (High Risk, High Reward)
- `max_hp = 60` (3 shots)
- `shot_cost = 20`, `recovery_percent = 1.2` (overheal on pickups)
- `regen_rate = 0` (no passive regen)
- Unique: Overflow HP increases damage

**Medic** (Sustain Tank)
- `max_hp = 140` (7 shots)
- `shot_cost = 20`, `recovery_percent = 0.6`
- `regen_rate = 8`, `regen_delay = 2.0`
- Unique: Can sacrifice HP to heal allies

**Efficient Marksman** (Precision)
- `max_hp = 100` (6-7 shots)
- `shot_cost = 15`, `recovery_percent = 0.8`
- `regen_rate = 3`, `regen_delay = 4.0`
- Unique: Consecutive hits increase recovery

### Procedural Generation Hooks

The current architecture supports room-based generation:

- **Tile flag system**: `fget(mget(tx, ty), SOLID_FLAG)` for wall detection
- **Entity spawning**: `Entities.spawn_*` factories for consistent initialization
- **Collision handlers**: Type-based for environment variations (spike tiles, hazards)

**Room Types:**
- Combat: Enemy-dense, guaranteed pickups
- Treasure: Powerup pedestals, high pickup density
- Challenge: Limited pickups, high enemy count
- Shop: Trade overflow HP for powerups/max HP increases

## Design Principles

### 1. **Clarity Over Complexity**
The three-state health bar makes the economy immediately understandable. Players should never wonder "Can I shoot?"

### 2. **Stat-Driven, Not Hardcoded**
All mechanics scale with player stats to support infinite variation via powerups and classes.

### 3. **Overflow as a Resource**
Rather than wasting excess HP, bank it for future mechanics. Creates secondary resource management.

### 4. **Snapshot, Don't Reference**
Projectiles carry their creation context. Enables mid-flight modifications and varied ammo types.

### 5. **Composition Over Inheritance**
Use additive systems (collision handlers, type-based behavior) rather than rigid class hierarchies.

## Open Questions

1. **Regen Balance**: Should base regen be 0 or 5? Currently 5 for testing, but might be too forgiving.
2. **Overflow Cap**: Should there be a maximum overflow_hp, or unlimited banking?
3. **Enemy HP Economy**: Should enemies drop HP pickups, or only wall-stuck projectiles?
4. **Death Penalty**: Permanent death vs. respawn with HP loss?
5. **Shot Variety**: Multiple fire modes (spread, charge, rapid) with different costs?