# Entity Spawning System

Pizak uses a flexible **Factory Pattern** combined with a **Data-Driven Spawner** to manage entity creation.

## Factory Architecture

All entity spawning flows through `src/entities/init.lua`, which aggregates specific factories (`player.lua`, `enemy.lua`, `projectile.lua`, `pickup.lua`).

### The `spawn_entity` Utility

Located in `src/entities/utils.lua`, this core function standardizes ECS entity registration:

1. Accepts `world`, `tags` (string), and `data` (table).
2. Creates the entity in the ECS world.
3. **Auto-Shadows**: If the `shadow` tag is present, it automatically spawns a linked `Shadow` entity.

### Type Object Pattern

Most factories (Enemy, Projectile, Pickup) use the **Type Object** pattern:

- **Config**: Defined in `src/game/game_config.lua`.
- **Spawn Call**: `Entities.spawn_enemy(world, x, y, "Skulker")`.
- **Process**:
    1. Look up "Skulker" in `GameConstants.Enemy`.
    2. Copy base properties (HP, speed, sprite).
    3. Create entity via `spawn_entity`.

## Spawner System (`src/systems/spawner.lua`)

The `Spawner` system manages *when* and *where* enemies appear in a room.

### Lifecycle Integration

Spawning is tightly coupled with the [Room Lifecycle](procedural_generation.md):

1. **Populated**: Room has enemy data assigned.
2. **Spawning**: Player enters room. A 1-second timer starts. Warning indicators blink.
3. **Active**: Timer finishes. Entities are created in the world. Doors lock.

### Positioning Logic

The spawner determines valid locations using three strategies:

1. **Pattern-Based**:
    - Uses `WavePatterns` (ASCII grids) to pick ideal spots.
    - Tries to match pattern positions to room coordinates.
    1. **Random Fallback**:
    - If no pattern or pattern fails, picks random floor tiles.
    - **Constraints**:
        - Must be a valid floor tile (no pits/rocks).
        - Must be `min_dist` away from player (default 80px).
        - Must not overlap other enemies.
    - **Nudging**: Uses a spiral search algorithm (`nudge_to_valid`) to find the nearest valid pixel if a chosen spot is blocked.

### Special Mechanic: Skull Pressure

- In cleared rooms, if the player lingers while hurt, a `Skull` spawns.
- **Logic**: Spawns **off-screen** at the farthest corner from the player to prevent cheap hits, then moves in.
