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

- **AI Behavior Modularization**: Extracted individual AI behaviors from the monolithic `src/systems/ai.lua` into a new `src/ai/` directory (`chaser.lua`, `shooter.lua`, `dasher.lua`). Refactored `src/systems/ai.lua` into a clean dispatcher module.
- **Renamed Redundant AI Function**: Renamed `AI.enemy_ai` to `AI.update` and updated its export in `Systems` to `Systems.ai` for better consistency with other systems.
- **Implemented Shooter Vision Range**: Added a distance-based activation check to the Shooter AI. Shooters now remain idle until the player enters their `vision_range` (200 pixels).
- **Implemented Random Wandering Behavior**: Created reusable `src/ai/wanderer.lua` module for enemies to wander randomly when the player is outside vision range. Integrated with Shooter AI - they now pick random nearby destinations and move toward them at 50% speed, pausing briefly between targets. Wandering is interrupted immediately when the player is spotted.
- **Implemented Isaac-Style Procedural Dungeon Generation**: Full implementation of PROCGEN.md phases:
  - **Expansion Loop**: Random walk algorithm with "Rule of One" constraint to prevent 2×2 room clusters. Configurable `TARGET_ROOM_COUNT = 8`.
  - **Specialization**: Distance-based room type assignment. Leaf nodes (1 neighbor) are assigned as BOSS (farthest), TREASURE, and SHOP. Remaining rooms become COMBAT with auto-assigned enemies.
  - **Door Connection**: Automatic bidirectional door creation via neighbor lookup.
  - Floor colors now reflect room type (red=boss, cyan=treasure, yellow=shop).
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
- **Implemented Enemy Death Animations**: Added procedural death effects for enemies using sprite manipulation:
  - **Squash and Stretch**: Enemies flatten vertically and expand horizontally using `sspr`.
  - **Palette Flash**: Enemies flash white and then flicker red/purple/gray.
  - **Shake**: Added random position jitter.
  - Configured `death` animation state in `GameConstants` with a 30-frame duration.
  - **Fixed death flow**: Removed immediate `world.del()` from collision handler, allowing FSM death state to play animation before cleanup.
- **Implemented Dual Pickup System with Extensible Architecture**:
  - **ProjectilePickup**: Spawned when player projectiles hit walls (maintains directional sprite from projectile).
  - **HealthPickup**: Spawned when enemies die (sprite 64, simple static pickup).
  - **Effect Registry**: Implemented `PickupEffects` registry in collision.lua that maps `pickup_type` to effect handlers.
  - **Type-based Dispatch**: Pickups now have a `pickup_type` field that determines which effect handler runs.
  - **Extensible Design**: New pickup types (ammo, powerups, coins) can be added by:
    1. Adding an effect handler to `PickupEffects` registry
    2. Creating a spawn function with the appropriate `pickup_type`
    3. No changes needed to collision handlers
  - See `docs/PICKUP_SYSTEM.md` for architecture details and examples.
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
- **Enhanced Skull Pressure Mechanic**:
  - Skulls now spawn in **locked combat rooms** after a 30-second delay (`SKULL_SPAWN_LOCKED_TIMER = 1800`), adding pressure during combat.
  - Skulls ignore the health check in locked rooms but respect it in cleared rooms (only spawn if player is hurt).
  - Skulls no longer display a health bar (`Rendering.draw_health_bar` skips entities with `skull` tag).
  - Implemented via `onenteractive` and `onentercleared` callbacks in the Room lifecycle FSM.
- **Improved Enemy Balance**:
  - Increased `Dasher` (Snail) vision range by 50% (from 100 to 150) to make it more aggressive in spotting the player.
- **Fixed Spotlight and Shadow Rendering**: The `clip()` function operates in screen coordinates, not world coordinates. When camera offsets are applied, the room's world-space `pixels` must be converted to screen-space by subtracting the camera scroll. This fix ensures spotlights and shadows render correctly regardless of camera position.
- **Implemented Skull Pressure Mechanic**:
  - Introduced a "skull" enemy that spawns in cleared combat rooms after a configurable timer (`SKULL_SPAWN_TIMER = 420` frames/7 seconds).
  - **Logic**: Only spawns if the player is below max health, preventing indefinite idle regeneration without movement.
  - **Properties**: 1 HP, immune to projectiles, deals 20 HP damage (one segment) on contact.
  - **Spawn Logic**: Spawns truly offscreen (32px beyond viewport) at the farthest corner from the player.
  - **Refactoring**: Implemented `map_collidable` ECS tag to distinguish between entity-map and entity-entity collisions. The skull is `collidable` but not `map_collidable`, allowing it to pass through walls.
  - **Cleanup**: `RoomManager` handles skull deletion on room transition and timer reset on re-entry.
- **Refactored Projectile System to Type Object Pattern**:
  - Consolidated `Projectile.spawn` and `Projectile.spawn_enemy` into a single unified `Projectile.spawn(world, x, y, dx, dy, projectile_type, instance_data)` function.
  - Moved all projectile type definitions (`Laser`, `EnemyBullet`) into `GameConstants.Projectile` as pure data objects, mirroring the Enemy system design.
  - Each projectile type config includes: `entity_type`, `tags`, `owner`, `speed`, `damage`, hitbox data, animation configs, shadow settings, and palette swaps.
  - Updated `Entities` module with convenience aliases (`spawn_laser`, `spawn_enemy_projectile`) and preserved backward compatibility.
- **Refactored Pickup System to Type Object Pattern**:
  - Consolidated `Pickup.spawn_projectile` and `Pickup.spawn_health` into a single unified `Pickup.spawn(world, x, y, pickup_type, instance_data)` function.
  - Moved all pickup type definitions (`ProjectilePickup`, `HealthPickup`) into `GameConstants.Pickup` as pure data objects.
  - Each pickup type config includes: `entity_type`, `tags`, `pickup_effect`, sprite settings, and hitbox data.
  - Added `hitbox_from_projectile` flag for pickups that inherit hitbox from projectile types.
  - Updated `Entities` module with generic `spawn_pickup` and convenience aliases for backward compatibility.
- **Unified Type Object Pattern Across All Entity Factories**:
  - All three factories (Enemy, Projectile, Pickup) now follow the same structure:
    1. Signature: `spawn(world, x, y, [type_specific_args], type_key, instance_data)`
    2. Config lookup: `GameConstants.<Category>[type_key]`
    3. Entity properties built from config
    4. Instance overrides applied with generic `for k,v in pairs(instance_data)` loop
    5. Entity created with `Utils.spawn_entity(world, config.tags, entity)` - auto-spawns shadows if tagged
  - Consistent type key naming: `enemy_type`, `projectile_type`, `pickup_type` stored on entities
  - Created shared `entities/utils.lua` with:
    - `get_direction_name(dx, dy, default)` - converts velocity to direction string with thresholding and fallback support.
    - `spawn_entity(world, tags, entity_data)` - centralized entity creation that auto-spawns shadows for entities containing the "shadow" tag.
  - **Data-driven Shadows**: Shadows are no longer manually spawned by factories. Adding the "shadow" tag to any entity in `constants.lua` automatically creates a linked `Shadow` entity via `Utils.spawn_entity`.
  - Added "shadow" tag to entity configs in constants.lua (Laser, EnemyBullet, Skulker, Shooter, Skull, Player).
  - Cleaned up dead code in `entities/init.lua`: removed `spawn_projectile`, `spawn_laser`, `spawn_pickup`, `spawn_shadow`.
  - Renamed to `spawn_player_projectile` and `spawn_enemy_projectile` for clarity.
- **Implemented Dasher Enemy (Snail)**:
  - **Configuration**: Added `Dasher` to `GameConstants.Enemy` with 60 HP (tank), slow speed (0.2), and Patrol/Windup/Dash/Stun behavior parameters.
  - **AI System**: Implemented `dasher_behavior` using `lua-state-machine` FSM:
    - **Patrol**: Random cardinal movement until blocked -> orthogonal turn.
    - **Windup**: 60-frame pause when spotting player, tracking player position.
    - **Dash**: Fast movement (4x speed) towards last seen player position.
    - **Stun**: 120-frame pause after collision with wall/player.
  - **Visuals**: Mapped `attacking` animation state to the "snail in shell" sprite (235) to visually represent the Dash/Shell mode, synchronized via FSM events.
  - **Collision**: Added logic to detect Dasher collisions during Dash state and trigger Stun.
- **Documentation & Task Management**:
  - Updated `ARCHITECTURE.md` to reflect unified factory patterns and data-driven shadows.
  - Updated `TODO.md` status for procedural generation and combat fixes.
- **Refactoring**: Extracted collision handlers from `collision.lua` to `src/systems/handlers.lua` to improve code organization and maintainability.
- **Simplification**: Refactored `src/systems/ai.lua` to use the built-in `sgn()` function for calculating entity directions, replacing complex ternary logic.
- **Implemented Door Guidance (Wall Sliding)**:
  - Added a "guidance" system to map collisions: when the player moves toward a wall tile adjacent to an unlocked door, they are nudged toward the door's center.
  - Centralized tile flags (`SOLID_FLAG`, `DOOR_FLAG`) and door sprites (`SPRITE_DOOR_OPEN`, `SPRITE_DOOR_BLOCKED`) as global constants in `constants.lua`.
  - Updated `Collision.resolve_map` to detect adjacent doors and apply a corrective velocity (1.5x base speed) on the orthogonal axis.
- **Implemented 1x3 Corridors and Visual Refinements**:
  - Expanded corridors between rooms to 1x3 dimensions (1 tile wide, 3 tiles long) with automatically carved walls.
  - **Seamless Transitions**: Unlocked doors are now replaced with tile 0 (empty passage) for a cleaner visual look.
  - **Transition Trigger**: Since doors are now empty, an invisible `TRANSITION_TRIGGER_TILE` (index 24) is placed in the middle of each 1x3 corridor to trigger room transitions.
  - **Dynamic Corridor Coloring**: Corridors now match the floor color of the room when it is unlocked, remaining black (background color) while the room is locked.
  - **Stateful Compatibility**: Updated `RoomManager` to use `getStateStackDebugInfo()` for state checks, maintaining compatibility with the third-party `Stateful` library without modification.
- **Implemented Room Lifecycle FSM**: Replaced scattered boolean flags (`spawned`, `is_locked`, `cleared`) with a single `lua-state-machine` FSM on the Room object.
  - **States**: `empty` (safe rooms), `populated` (has enemy config), `spawning` (countdown active), `active` (combat in progress), `cleared` (all enemies dead).
  - **Transitions**: `enter` (populated→spawning), `spawn` (spawning→active), `clear` (active→cleared).
  - **Door Updates**: FSM callbacks handle door sprite changes automatically on state entry.
  - **Consumers Updated**: `RoomManager`, `Spawner`, and `Handlers` now use `room.lifecycle:is()` / `room.lifecycle:can()` instead of flags.
- **Fixed Player Stuck Behind Door Bug**: Adjusted player spawn position calculations in `CameraManager` during room transitions. Now accounts for player width/height when entering from East/South to prevent spawning inside walls/doors (ensures an 8px safe gap).
- **Code Cleanup**: Removed duplicated directions table in `DungeonManager.generate` in favor of the `DIRECTIONS` constant. Removed redundant `is_safe`, `enemy_positions`, and `spawn_timer` initializations in `DungeonManager` as they are now handled by the Lifecycle FSM and `Spawner` system.
- **Implemented Room Screen Centering**:
  - `CameraManager` now automatically centers rooms smaller than the screen.
  - Room dimensions adjusted to 29x16 tiles (464x256 pixels) to create balanced margins.
  - `Room:draw()` now only fills the inner floor bounds (excluding walls) to prevent floor bleed.
  - `DungeonManager.carve_room()` carves extra wall tiles in the margin area (calculated from screen gap) to fill visible space beyond room bounds.
  - `DungeonManager.carve_corridors()` simplified to pierce door tiles in both current and adjacent rooms.
  - Removed manual `MAP_DRAWING_OFFSET` from camera calculation; centering is now fully automatic.
- **Implemented Rotated and Stretched Door Sprites**:
  - Blocked door sprites (sprite 6) are now drawn with rotation so the bottom of the sprite faces the room center.
  - Added `Rendering.draw_doors(room)` function that uses the `sprite_rotator` module to apply direction-based rotation.
  - Rotation angles: North doors: 0°, South doors: 180°, East doors: 90°, West doors: 270°.
  - Doors are stretched using `sspr` to span 1.5 tiles (24 pixels) to cover the gap between wall and floor.
  - `DungeonManager.apply_door_sprites()` sets blocked door tiles to 0 (empty) in the map, allowing manual drawing with rotation and stretching.
- **Restored Dynamic Room Transitions**: When the player's world position exits the current room's pixel bounds (e.g., by entering a door opening), a transition is triggered. The `CameraManager` enters a `Scrolling` state, teleports the player to the entrance of the target room, and smoothly interpolates the camera position from the old room to the new one over 30 frames. During this scroll, both rooms are rendered to the screen. Once complete, the camera returns to its `Following` (clamping) state and the target room becomes the new active room.
- **Room Lifecycle**: Each room has an internal FSM (`populated`, `spawning`, `active`, `cleared`) that controls enemy spawning and door status.
- **Directly Adjacent Rooms**: Following the *The Binding of Isaac* style, rooms are carved at contiguous grid positions (e.g., Room 1 at grid `0,0` and Room 2 at `1,0`). This results in a 2-tile thick wall boundary between rooms, which is pierced by clearing the door tiles in both rooms when they are connected.
- **Skull Pressure Mechanic**: Cleared combat rooms initialize a `SKULL_SPAWN_TIMER` (in `constants.lua`). If the player remains in a cleared room while below max health, a projectile-immune "skull" enemy spawns offscreen at the farthest corner to force progression. The skull can pass through walls (`collidable` but not `map_collidable`).
