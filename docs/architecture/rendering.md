# Rendering System

The rendering system in Pizak uses a **Y-sorted 2.5D approach** to simulate depth in a top-down perspective. It handles everything from individual sprite effects to global lighting and shadow simulation.

## Core Principles

### Y-Sorted Depth

To maintain the illusion of depth, entities are rendered from top to bottom based on their "foot" position.

- **Calculation**: `sort_y = entity.y + (entity.sort_offset_y or entity.height or 16)`
- **Implementation**: `Rendering.draw_layer` uses `qsort` to order entities before drawing.

### Z-Axis Simulation

The game uses a logical `z` property to simulate height (jumping, flying projectiles).

- **Visual Displacement**: `draw_y = y - z + sprite_offset_y`.
- **Grounding**: The logical position `(x, y)` remains on the ground for collision and shadow anchoring, while the sprite is offset vertically.

## Layer System

Rendering is divided into distinct layers to ensure correct overlapping:

1. **Background**: Floor tiles, room walls, and static ground features.
2. **Shadows**: Oval shadows drawn behind all entities.
3. **Entities (Middleground)**: Players, enemies, projectiles, and pickups. This layer is Y-sorted.
4. **Lighting Overlay**: The darkness/spotlight layer.
5. **UI (Foreground)**: HUD, Minimap, and screen-space text.

## Shadow System

Shadows are implemented as dedicated entities for maximum flexibility.

- **Syncing**: Any entity with the `shadow` tag automatically spawns a linked `Shadow` entity. The `Shadows.sync` system copies position and dimensions from the parent every frame.
- **Anchoring**: Shadows are anchored to the ground (`y` position) and do not follow the `z` displacement of the parent.
- **Dynamic Sizing**: Shadow width defaults to 80% of the hitbox width but can be overridden per-direction in `game_config.lua`.

## Lighting & Palette System

Pizak uses Picotron's extended palette (colors 32-63) to create lighting effects.

- **Palette Initialization**: `init_extended_palette()` creates a "brightness ramp" (32-47) and a "darkness ramp" (48-63) for all 16 base colors.
- **Spotlights**: Entities with the `spotlight` tag render a `circfill` using `LIGHTING_SPOTLIGHT_COLOR`. Picotron's hardware transparency (`poke(0x550b, 0x3f)`) maps this color to the brightness ramp.
- **Darkness**: The screen is covered with a shadow color that maps to the darkness ramp, except where spotlights are active.

## Sprite Effects

### Outlines

Used for emphasizing important entities (e.g., active items or projectiles).

- **Technique**: Draws the sprite 8 times at 1px offsets (N, S, E, W, NE, NW, SE, SW) using a solid color before drawing the main sprite.
- **Composite Support**: Handles monsters split across multiple sprites with `draw_outlined_composite`.

### Flash & Feedback

- **Flash**: Toggled via `flash_timer` in `Effects.update_flash`. Swaps palette to white/red for impact feedback.
- **Death Animation**: A procedural effect that combines vertical squashing, horizontal stretching, and rapid palette flickering over 30 frames.

### Composite Sprites

Allows for large entities by combining a `sprite_top` and `sprite_bottom` indexed by a `split_row` pixel offset.

## Visibility Filtering

To optimize performance and handle room transitions, entities use a `room_key`.

- `Rendering.set_active_rooms({"x,y", ...})` determines which rooms are visible.
- Entities are only rendered if their `room_key` matches an active room or if they have no `room_key` (global entities like the player).
