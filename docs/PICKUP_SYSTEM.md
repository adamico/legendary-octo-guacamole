# Pickup System Architecture

## Overview

The pickup system uses a **type-based effect registry** to support multiple pickup types with different effects. This allows easy extension without modifying collision handlers.

## Architecture

### 1. Pickup Entity Structure

All pickups are created via spawn functions in `src/entities/pickup.lua`:

- `Pickup.spawn_projectile()`: For projectile wall collisions (directional)
- `Pickup.spawn_health()`: For enemy death drops (simple)
- Custom spawners for new pickup types

All pickups must have:

- `type`: Entity identifier (e.g., "ProjectilePickup", "HealthPickup", "CoinPickup")
- `pickup_type`: Effect identifier (e.g., "health", "ammo", "speed_boost")
- Effect parameters (e.g., `recovery_amount`, `boost_duration`)

**Internal Helper**: `spawn_base(config)` eliminates duplication by handling common pickup properties.

### 2. Effect Registry

Located in `src/physics/handlers.lua`, the `PickupEffects` registry maps `pickup_type` to handler functions:

```lua
local PickupEffects = {}

PickupEffects.health = function(player, pickup)
    player.hp = player.hp + (pickup.recovery_amount or 16)
    -- Handle overflow...
end
```

### 3. Collision Handler

The unified `handle_pickup_collection` function:

1. Reads `pickup.pickup_type`
2. Looks up handler in `PickupEffects` registry
3. Calls the handler
4. Triggers visual/audio feedback
5. Deletes the pickup

## Adding New Pickup Types

### Example: Speed Boost Pickup

#### 1. Add Effect Handler (`src/physics/handlers.lua`)

```lua
PickupEffects.speed_boost = function(player, pickup)
    local duration = pickup.boost_duration or 300 -- 5 seconds at 60fps
    local multiplier = pickup.speed_multiplier or 1.5
    
    player.speed_boost_timer = duration
    player.speed_boost_multiplier = multiplier
    
    Log.trace("Speed boost activated: " .. multiplier .. "x for " .. duration .. " frames")
end
```

#### 2. Create Spawn Function (`src/entities/pickup.lua`)

```lua
function Pickup.spawn_speed_boost(world, x, y, duration, multiplier)
    return spawn_base({
        type = "SpeedBoostPickup",
        pickup_type = "speed_boost", -- Links to effect registry
        x = x,
        y = y,
        sprite_index = 65, -- Your sprite for speed boost
        boost_duration = duration or 300,
        speed_multiplier = multiplier or 1.5,
    })
end
```

#### 3. Register in Entities Module (`src/entities/init.lua`)

```lua
Entities.spawn_speed_boost = Pickup.spawn_speed_boost
```

#### 4. Update Player Physics (`src/systems/physics.lua`)

```lua
function Systems.acceleration(entity)
    local boost = entity.speed_boost_multiplier or 1.0
    
    -- Tick down boost timer
    if entity.speed_boost_timer and entity.speed_boost_timer > 0 then
        entity.speed_boost_timer -= 1
        if entity.speed_boost_timer <= 0 then
            entity.speed_boost_multiplier = 1.0
        end
    end
    
    -- Apply boosted acceleration
    entity.vel_x += entity.acc_x * boost
    entity.vel_y += entity.acc_y * boost
    -- ... friction, clamping, etc.
end
```

## Current Pickup Types

| Type | Entity | Sprite | Effect |
|------|--------|--------|--------|
| `health` | ProjectilePickup | 77/78 | Restore HP, bank overflow |
| `health` | HealthPickup | 64 | Restore HP, bank overflow |

## Future Pickup Ideas

- **`ammo`**: Restore ammo/shots (if ammo system is added)
- **`speed_boost`**: Temporary speed increase
- **`damage_boost`**: Temporary damage increase
- **`invincibility`**: Temporary invulnerability
- **`coin`**: Currency for shops
- **`key`**: Unlock special doors/chests
- **`bomb`**: Explosive item for destructible walls
- **`max_hp_upgrade`**: Permanent max HP increase

## Benefits

- ✅ **Extensible**: Add new pickup types without touching collision code
- ✅ **Decoupled**: Effect logic separated from collision detection
- ✅ **Type-safe**: Unknown pickup types log warnings instead of crashing
- ✅ **Flexible**: Same entity type can have different effects via `pickup_type`

---

## Spritesheet Pickup Ideas

Based on the available sprites, here are the recommended pickups:

### 💰 Coins (Spendable Currency)

| Pickup | Sprite Location | Value | Notes |
|--------|-----------------|-------|-------|
| **Gold Coin** | Sheet 2, row 2 (animated orange orbs) | 1 | Common drop from enemies, breakables |
| **Gem** | Sheet 2, row 6 (blue/pink diamonds) | 10-25 | Rare, secret rooms |
| **Trophy** | Sheet 2, top row (gold cup) | 50 | Boss drops |

**Uses**: Shop purchases, slot machines, donation boxes, toll doors.

---

### 🔑 Keys

| Pickup | Sprite Location | Type | Notes |
|--------|-----------------|------|-------|
| **Bronze Key** | Sheet 1, middle (golden key) | Standard | Opens treasure rooms, locked chests |
| **Key Ring** | Sheet 1, row 3 | Multi-use | Opens multiple doors |

**Uses**: Treasure rooms, locked chests, vault rooms, floor shortcuts.

---

### 💣 Bombs

| Pickup | Sprite Location | Type | Notes |
|--------|-----------------|------|-------|
| **Standard Bomb** | Sheet 1, row 3 (black bomb with fuse) | Basic | Destroys tiles, damages enemies |

**Uses**:

- **Combat**: Area damage, crowd control
- **Exploration**: Reveal secret rooms (weak walls)
- **Environment**: Remove destructible tiles for shortcuts

---

### ✨ Bonus Pickups

| Pickup | Sprite Location | Effect |
|--------|-----------------|--------|
| **Star** | Sheet 2, rows 1-2 (yellow stars) | Invincibility / damage boost |
| **Lightning** | Sheet 2, row 6 (yellow bolt) | Speed boost |
| **Clock** | Sheet 3, middle | Time freeze / slow-mo |
| **Bell** | Sheet 1, bottom (gold bell) | Alert / summon |

---

### Sprite Index Reference

> **TODO**: Map exact sprite indices once integrated into `constants.lua`

| Pickup Type | Suggested Sprite Index |
|-------------|----------------------|
| Coin | TBD (animated) |
| Key | TBD |
| Bomb | TBD |
| Heart | 64 (already in use) |
| Gem | TBD |
