# Memory

This file serves as a persistent memory for the AI assistant to track long-term goals, project state, and important context.

## References

- [Architecture Documentation](ARCHITECTURE.md)
- [Design Goals](DESIGN.md)
- [Research Notes](RESEARCH.md)
- [Todo List](TODO.md)

## Current Context

The project is a Picotron game (Lua-based) using an ECS architecture.

### Recent Activities

- **Implemented configurable hitboxes** with per-direction support for asymmetric sprites (e.g., laser 14x6 vertical, 6x14 horizontal). Uses `entity.hitbox[direction]` or falls back to `hitbox_*` properties.
- **Implemented FSM-based animation system** with per-frame durations, composite sprites, and velocity-based direction.
- Updated architecture documentation.
- Implemented knockback and invulnerability.
- Fixed palette-aware lighting and spotlight effects.
- Refactored player movement to use ECS (controllable, acceleration, velocity systems).
- Fixed map collision issues.
- Established context workflow in `.agent/workflows/context.md`.
- **Fixed projectile spawning** to always originate from the shooter's center and **implemented layered rendering** (projectiles and pickups are now rendered behind characters).
- **Fixed projectile-map immediate collision bug** by aligning projectile hitboxes with the player's core collision footprint [3, 13] x [4, 16], preventing "protrusion" hits against walls the player is currently touching.
- **Implemented random enemy spawning**: Enemies are now spawned at random positions within the room area, ensuring a minimum distance from the player and avoiding solid tiles.
- **Added room entry timer and blinking visualization**: Enemies now spawn after a 1-second delay upon entering the Play scene. During this delay, sprite 207 is displayed with a blinking effect at the pre-calculated spawn positions to indicate where enemies will appear.
- **Fixed room clipping and unit normalization**: Introduced `ROOM_PIXELS` to handle tile-to-pixel conversion for `ROOM_CLIP`, fixing an issue where spawn indicators and lighting effects were being incorrectly clipped.
- **Fixed enemy spawn overlap logic**: Resolved a crash in `is_free_space` by correcting argument passing and implementing a distance-based check to prevent enemies from spawning on the same pixel.
- **Extracted Spawner System**: Moved enemy spawning logic (random position calculation, timer, and blinking indicators) from `play.lua` into a dedicated `Systems.Spawner` module (`src/systems/spawner.lua`). Cleaned up the coordinate calculation and added support for spawning multiple enemy types.
- **Implemented Shooter Enemy and AI Refactor**: Added a new "Shooter" enemy type with unique AI that maintains distance from the player and fires projectiles. Refactored the AI system to support modular behaviors based on enemy type.
- **Refactored Shadow System to Independent Entities**: Replaced the previous tag-based shadow system with a dedicated `Shadow` entity architecture. Added support for dual-syntax configuration in `constants.lua`: both global/simple properties (`shadow_offset`, `shadow_width`) and per-direction overrides (`shadow_offsets`, `shadow_widths`).
- **Enhanced Animation System Fallbacks**: Updated the animation system to support both directional (nesting under `down`, `up`, etc.) and global (top-level `idle`, `walking`) syntaxes. Implemented a 4-tier fallback: Direction-specific State -> Direction-specific Idle -> Global State -> Global Idle.
- **Refined projectile centering and alignment**: Synchronized hitboxes with flying elevation so they perfectly match the visual sprite. Decoupled shadows from hitbox elevation, anchoring them firmly to the ground line (`entity.y + height`). Implemented per-direction `shadow_offsets` support, allowing for precise grounding as entity sprites change direction.
- **Implemented Isaac-style projectile aerials**: Significantly increased projectile elevation and support for detached shadows (`shadow_offset_y`). Enforced a minimum shadow width of 8px to maintain visual presence for thin projectiles like lasers.
- **Implemented dynamic shadow sizing and aesthetic refinements**: Shadow width and position are now calculated from the entity's hitbox dimensions with professional scaling (80% width) and flattening (3px height). Tucked shadows slightly into the sprite base for a better grounded feel.
- **Enhanced hitbox lookup**: Updated `Collision.get_hitbox` to support `current_direction` as a fallback, ensuring compatibility with the FSM-based animation system.
- **Implemented EnemyProjectile Collisions**: Added collision handlers for `EnemyProjectile` to ensure they are deleted upon hitting walls or the player, and deal damage/knockback to the player.
- **Implemented Sprite Flip Support**: Enhanced the animation and rendering systems to support both horizontal and vertical flips using boolean properties (`flip_x`, `flip_y`). Added support for per-frame flips via a `flips` table in animation configurations.
- **Enabled Projectile Animations**: Updated the animation system to handle simplified directional configs (no state nesting) and added the `animatable` tag to player projectiles, enabling effects like spinning lasers.
- **Implemented Dead Player Deactivation**: Added logic to the animation system to remove active ECS tags (`controllable`, `collidable`, `shooter`, `player`, etc.) from entities upon entering the `death` state. This ensures dead entities are ignored by AI and collisions, and cannot be controlled, while remaining rendered on screen.
- **Implemented Enemy Freeze on Player Death**: Updated the AI system to zero out enemy velocity and direction when no player entity is found, causing enemies to stop in place upon player death.
- **Refactored Dungeon Management**: Renamed `RoomManager` to `DungeonManager` and implemented grid-based dungeon generation with safe starts and enemy rooms.
- **Implemented Single-Screen Rendering**: Switched to a model where rooms are carved into the (0,0) map area on each transition, simplifying camera and coordinate management.
- **Implemented Room Locking Mechanics**: Doors now lock (sprite 4) upon room entry and unlock (sprite 3) only after all enemies are defeated. Improved robustness by checking spawner completion state.
- **Enhanced Door Transitions**: Improved door collision detection with multi-point hit checks and reliable player teleportation between rooms.
- **Cleaned Up Logic**: Removed manual solid flag setting in favor of Picotron sprite editor flags and optimized entity cleanup during transitions.
- **Fixed RoomManager Stateful Integration**: Added a top-level `update()` method to `RoomManager` that delegates to the current state's update method, resolving "Undefined field `update`" error when using the Stateful library.
- **Implemented Zelda-style Room Transitions**: Added a `Scrolling` state to `RoomManager` that handles smooth transitions between rooms with camera interpolation.
- **Single Source of Truth (Absolute World Coordinates)**: Refactored the entire coordinate system so that `Room` objects store absolute tile and pixel positions on an extended 80x48 map. This eliminates the need for constant "base offset" additions and guarantees visual consistency across all systems (collision, spawning, rendering).
- **Extended Map System**: Implemented a custom map userdata (`80x48`) that provides margin on all sides of the visible screen area, allowing the previous room's walls to remain visible during transitions (the "peek" effect).
- **Refactored Dungeon and Room Management**:
  - `DungeonManager`: Handles world-level generation, room placement on the grid, map carving, and player spawn calculations.
  - `RoomManager`: Handles the visual state machine (Exploring, Scrolling, Settling) and manages camera offsets and floor rendering.
- **Fixed South Door Collision**: Resolved a coordinate mismatch in `identify_door` by aligning it with the new absolute world coordinate system.
- **Refactored Entity Rendering**: Moved `draw_entity` from `play.lua` to `Systems.draw_entity_with_flash` in `src/systems/rendering.lua` to sanitize the Play scene loop and centralize rendering logic.
- **Accurate Player/Enemy Positioning**: Ensured that the player and enemies spawn correctly within the world coordinate space of each room, fixing rendering bugs after transitions.
- **Code Quality & Linting**: Established pattern of declaring manager instances (e.g., `room_manager` in `play.lua`) as `local` variables rather than globals. This resolves "Undefined field" linting ambiguities and matches the `SceneManager` pattern in `main.lua`.
- **Fixed Spotlight and Shadow Rendering**: The `clip()` function operates in screen coordinates, not world coordinates. When camera offsets are applied, the room's world-space `pixels` must be converted to screen-space by subtracting the camera scroll. This fix ensures spotlights and shadows render correctly regardless of camera position.
