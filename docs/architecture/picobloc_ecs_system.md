# Picobloc ECS System

## Why?

The eggs.p8 ECS system shows performance limits with many entities. Picobloc leverages Picotron's userdata and batch GFX features for better performance.

## Architecture

### Component Definition

Components are defined in `src/components.lua` using typed fields:

```lua
world:component("position", {x = "f64", y = "f64"})
world:component("velocity", {vel_x = "f64", vel_y = "f64"})
world:component("shadow", {
   shadow_offset_x = "f64",
   shadow_offsets_x = "value",  -- Tables use "value" type
})
```

**Field types:**

- `f64`, `u64`, `i64` - Numeric types stored in userdata
- `value` - Lua tables/booleans stored in plain tables

### Tag Components

Tags are empty components for filtering:

```lua
world:tag("player", "controllable", "sprite", "middleground")
```

### Entity Creation

Entities use nested component structure:

```lua
local id = world:add_entity({
   player = true,  -- Tag shorthand
   position = {x = 100, y = 100},
   shadow = {
      shadow_width = 12,
      shadow_offsets_y = {down = 2, up = -1},  -- Per-direction config
   },
})
```

### Querying

Systems use `world:query()` with component lists:

```lua
-- Required + optional components
world:query({'position', 'shadow', 'direction?'}, function(ids, pos, shadow, dir)
   for i = ids.first, ids.last do
      local x = pos.x[i]
      local offsets = shadow.shadow_offsets_y[i]  -- Access "value" fields
   end
end)
```

**Query modifiers:**

- `component` - Required
- `component?` - Optional (may be nil)
- `!component` - Exclude entities with this component

## Migrated Systems

| System | Status | Query |
|--------|--------|-------|
| Shadows | ✅ Done | `position`, `shadow`, `size`, `direction?` |
| Rendering | ✅ Done | `position`, `drawable`, `size?`, ... |
| Animation | ✅ Done | `drawable`, `animatable`, `direction`, `type` |
| Lighting | ✅ Done | `position`, `spotlight` |
| FloatingText | ✅ Done | `position`, `floating_text` |
| Player | ✅ Done | Uses all player components |

## Key Differences from Eggs

| Eggs | Picobloc |
|------|----------|
| `world.sys("tag1,tag2", fn)` | `world:query({'comp1', 'comp2'}, fn)` |
| `entity.property` | `component.field[index]` |
| String tags | Typed components |
| Entity tables | Entity IDs + buffers |

## Migration Master Plan

### Phase 1: Foundation ✅

- [x] Define player specific components in `src/components.lua`
- [x] Define other entity specific components in `src/components.lua`
- [x] Add `world:tag()` shorthand to picobloc
- [x] Verify `world:tag()` works in picobloc queries (tags are queried like components)
- [x] Migrate Player entity to picobloc
- [x] Migrate other entities to picobloc (enemy, obstacle, pickup, projectile, minion, bomb, explosion)

### Phase 2: Visual Systems ✅

- [x] **Shadows** - Query `position + shadow + size`
- [x] **Rendering** - Y-sorted entity drawing
- [x] **Animation** - Sprite state machine
- [x] **Lighting** - Spotlight effects
- [x] **Floating Text** - Damage/heal numbers

### Phase 3: Core Systems ✅

- [x] **Physics** - Movement, velocity, acceleration
- [x] **Collision** - Spatial grid, entity-entity, entity-map
- [x] **Timers** - Cooldowns, invulnerability

### Phase 4: Combat Systems ✅

- [x] **Shooter** - Projectile spawning
- [x] **Melee** - Hitbox spawning
- [x] **Effects** - Knockback, stun, slow

### Phase 5: Entity Factories

- [x] **Enemy** - Skulker, Shooter, Dasher, Skull
- [x] **Projectile** - Egg, EnemyBullet
- [x] **Pickup** - Health, Coin, Key, Bomb, XP
- [x] **Minion** - Chick
- [x] **Obstacle** - Rock, Destructible, Chest
- [x] **Bomb/Explosion**

### Phase 6: AI & Spawning ✅

- [x] **AI dispatch** - Enemy behavior FSMs (using EntityProxy)
- [x] **Spawner** - Wave patterns, room population (player ID passed directly)

### Phase 7: Cleanup ✅

- [x] Remove eggs.p8 dependency
- [x] Delete `src/entities/shadow.lua` (no longer needed)
- [x] Update all `world.sys()` → `world:query()`

## Files

- [picobloc.lua](file:///home/kc00l/game_dev/pizak/lib/picobloc/picobloc.lua) - Library
- [components.lua](file:///home/kc00l/game_dev/pizak/src/components.lua) - Component definitions
- [player.lua](file:///home/kc00l/game_dev/pizak/src/entities/player.lua) - Example entity
- [shadows.lua](file:///home/kc00l/game_dev/pizak/src/systems/shadows.lua) - Migrated system
