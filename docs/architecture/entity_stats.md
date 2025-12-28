# Entity Stats System

The entity stats system in Pizak acts as the central definition for game balance, decoupling data from logic using the **Type Object** pattern.

## Configuration Source

All base stats are defined in `src/game/game_config.lua` (exported as `GameConstants`). This file serves as the "Source of Truth" for:

- Player attributes
- Enemy types and behaviors
- Projectile specifications
- Pickup configurations

## Player Stats

The Player entity (`src/entities/player.lua`) combines static configuration with dynamic runtime properties.

### Combat Stats

| Stat | Description | Default |
| :--- | :--- | :--- |
| `max_hp` | Maximum health points (100 = 5 hearts). | 100 |
| `max_speed` | Movement speed in pixels/frame. | 2 |
| `shot_speed` | Speed of fired projectiles. | 4 |
| `range` | Projectile lifetime distance in pixels. | 200 |
| `fire_rate` | Cooldown frames between shots. | 15 |
| `knockback` | Force applied to enemies on hit. | 4 |
| `vampiric_heal` | Percentage of melee damage returned as HP. | 30% |

### Dynamic Scaling

Instead of fixed values, some stats scale with player health to create "Risk vs Reward" or "Power Progression" mechanics:

- **Damage**: Calculated as `max_hp * max_hp_to_damage_ratio` (default 0.2). Increasing Max HP increases damage.
- **Shot Cost**: Calculated as `max_hp * max_hp_to_shot_cost_ratio` (default 0.2). Shooting costs 1 segment of health (if `health_as_ammo` is true).

## Enemy Types

Enemies are defined in `GameConstants.Enemy` and instantiated by `src/entities/enemy.lua`.

### Type Definition Structure

```lua
Skulker = {
    entity_type = "Enemy",
    tags = "enemy,velocity,collidable,...", -- ECS Tags
    hp = 20,                               -- Health
    max_speed = 0.5,                       -- Move Speed
    contact_damage = 10,                   -- Touch Damage
    vision_range = 120,                    -- AI Detection Radius
    -- Visuals
    width = 16, height = 16,
    hitbox_width = 12, hitbox_height = 10,
    animations = { ... }
}
```

### Specialized Behaviors

Some enemies have specific AI parameters configured here:

- **Shooter**: `shot_speed`, `damage`, `range`, `shoot_delay`.
- **Dasher**: `windup_duration`, `dash_speed_multiplier`, `stun_duration`.

## Projectiles

Projectiles (`GameConstants.Projectile`) are also data-driven. This allows different weapons (Player Laser vs Enemy Bullet) to share the same ECS code (`src/entities/projectile.lua` and `src/systems/shooter.lua`).

- **Owner**: `"player"` or `"enemy"` (determines collision logic).
- **Visuals**: `sprite_index_offsets`, `palette_swaps`, `shadow_offsets`.
- **Physics**: `speed`, `knockback`, `hitbox` (directional).

## Hitboxes & Shadows

Collision and rendering logic use decoupled data:

- **Hitbox**: Defined separately from sprite dimensions (`hitbox_width`, `hitbox_offset_x`) to allow forgiving collision (hitbox smaller than sprite).
- **Shadows**: Configured per-entity to ground them visually.
  - `shadow_width` / `shadow_height`: Size of the oval.
  - `shadow_offset`: Vertical distance from the entity `y` position.
