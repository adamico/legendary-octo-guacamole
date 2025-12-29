# Physics Simulation

The physics system in Pizak handles movement, gravity, and simulated height (z-axis) for visual effect while keeping collision detection in 2D.

## System Location

- **Main physics**: `src/systems/physics.lua`
- **Z-axis integration**: `Physics.z_axis()` function

## Core Coordinate System

The game uses a pseudo-3D coordinate system:

| Property | Description |
| ---------- | ------------- |
| `entity.x` | Horizontal position (world space) |
| `entity.y` | Shadow/ground position (where collision happens) |
| `entity.z` | Height above ground (visual offset only) |
| `visual_y` | Where sprite appears = `entity.y - entity.z` |

The shadow is rendered at `entity.y`, while the sprite is rendered at `entity.y - entity.z`.

## Z-Axis Physics

### Gravity and Flight

Projectiles use z-axis to simulate arcing flight:

1. **Launch**: Projectile spawns with `z = projectile_origin_z` (configured per shooter)
2. **Flight (first 75%)**: z stays constant, projectile moves horizontally/vertically
3. **Drop (last 25%)**: Gravity accelerates `vel_z`, z decreases toward 0
4. **Landing**: When `z <= 0`, projectile lands and hatches/spawns pickup

### Gravity Calculation

```lua
-- Gravity is calculated to drop from z0 to 0 over drop_duration frames
local drop_duration = max_age * 0.25
gravity_z = (-2 * z0) / (drop_duration ^ 2)
```

## Horizontal vs Vertical Shots

Different shot directions require different landing animations:

| Aspect | Horizontal (left/right) | Vertical (up/down) |
|--------|------------------------|-------------------|
| z value | > 0 (elevated) | > 0 (elevated) |
| Flight | Sprite at y-z, shadow at y | Sprite at y-z, shadow at y |
| Landing | Sprite drops toward shadow | Shadow moves toward sprite |
| Flag | `vertical_shot = false` | `vertical_shot = true` |

### Why Different?

- **Horizontal**: The projectile flies through the air. Landing = falling down to ground.
- **Vertical**: The projectile moves along the Y-axis. The z-offset is purely visual. When it collides, the collision point IS the visual position, so the shadow must "catch up" to match.

## Critical Implementation Details

### 1. Ground Collision

When `z <= 0`, must set BOTH values:

```lua
if entity.z <= 0 and entity.gravity_z and entity.gravity_z < 0 then
   entity.z = 0
   entity.vel_z = 0  -- CRITICAL: Stop gravity accumulation
end
```

**Why?** Without `vel_z = 0`, gravity keeps accelerating and z goes further negative each frame, causing visual glitches or runaway values.

### 2. Y Adjustment for Vertical Shots

Only adjust Y while still airborne:

```lua
if entity.vertical_shot and entity.vel_z < 0 and entity.z > 0 then
   entity.y += (entity.z - prev_z)  -- z_delta is negative
end
```

**Why the `z > 0` guard?** Once grounded (z = 0), the adjustment should stop. Without this, Y keeps decreasing forever.

### 3. Hitbox Position

`get_hitbox()` returns the hitbox at the VISUAL position:

```lua
y = entity.y + offset + sprite_offset_y - entity.z
```

This means:

- Collision detection happens at the visual position (where you see the sprite)
- When spawning pickups at hitbox center, no additional z adjustment is needed
- The hitbox "follows" the sprite, not the shadow

### 4. Pickup Spawn from Collision

When a projectile hits something and spawns a pickup:

```lua
local hb = HitboxUtils.get_hitbox(projectile)
local spawn_x = hb.x + hb.w / 2 - half_pickup_w
local spawn_y = hb.y + hb.h / 2 - half_pickup_h
Entities.spawn_pickup_projectile(world, spawn_x, spawn_y, ..., projectile.z, projectile.vertical_shot)
```

The pickup inherits:

- `z` - Same height, will fall down with gravity
- `vertical_shot` - Same landing behavior (shadow catches up for vertical)

## Common Pitfalls

1. **Forgetting `vel_z = 0`**: Causes runaway negative z values
2. **Missing `z > 0` guard**: Causes Y to decrease forever after landing
3. **Double z subtraction**: If hitbox already subtracts z, don't subtract again in spawn
4. **Not passing `vertical_shot` to pickups**: Pickup will use wrong landing animation
