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
