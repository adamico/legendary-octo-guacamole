# Player Stats System Walkthrough

I have implemented the **Player Stats System**, which decouples combat statistics from static projectile configuration and moves them to the `Player` entity. This is the foundational step for implementing powerups, items, and dynamic builds.

## Changes

### 1. Configuration (`game_config.lua`)

- **Moved Stats**: `speed`, `knockback` moved from `Projectile.Laser` to `Player`.
- **New Stats**:
  - `shot_speed = 4`
  - `max_hp_to_damage_ratio = 0.2` (Replaces hardcoded damage)
  - `range = 100` (Determines shot lifetime)
  - `fire_rate = 15`
- **Inventory**: Added `coins`, `keys`, `bombs` defaults (0).

### 2. Player Entity (`player.lua`)

- **Initialization**: Player now initializes with these stats.
- **Derived Damage**: `damage` is calculated as `max_hp * max_hp_to_damage_ratio` (initially 100 * 0.2 = 20).

### 3. Projectile System (`projectile.lua`)

- **Dynamic Stats**: `Projectile.spawn` now accepts `instance_data` overrides for `speed`, `damage`, `knockback`, etc.
- **Velocity Calculation**: Logic updated to use the *overridden* speed (if provided) when calculating velocity, rather than the static default.

### 4. Shooter System (`shooter.lua`)

- **Stat Passing**: When firing, the shooter's current stats (`shot_speed`, `damage`, `range`, etc.) are passed to the projectile.
- **Lifetime**: Calculated as `range / shot_speed`.

## Verification Results

### Manual Check

- **Standard Shooting**: The game should behave exactly as before (Laser speed 4, Damage 20).
- **Synergy**: Increasing Max HP (e.g. via console or debug) will now automatically increase Damage.
- **Stat Modifiers**: Changing `player.shot_speed` will correctly make yours subsequent shots faster.

### Debug UI

- Added a new **Player Stats** group to the F1 debug panel.
- Displays real-time: `damage`, `shot_speed`, `range`, `fire_rate`, `HP Ratio`.
- Displays inventory: `coins`, `keys`, `bombs`.
