# Event System

The game uses a **Publish-Subscribe (Pub/Sub)** pattern to handle cross-module communication without direct dependencies. This is particularly useful for UI updates, achievements, and "action-at-a-distance" game logic.

## Implementation

The system is a wrapper around the `beholder.lua` library, located in `src/game/events.lua`.

### Key Features

1. **Typed Events**: Uses string constants (e.g., `Events.ROOM_CLEAR`) to prevent typo-related bugs.
2. **Global Access**: The `Events` module is globally available via `require("src/game/events")`.
3. **Scene Lifecycle Management**: Events are reset on scene exit to prevent memory leaks or zombie callbacks.

## API Reference

```lua
local Events = require("src/game/events")

-- constants
Events.ROOM_CLEAR      -- Payload: room_object
Events.ROOM_TRANSITION -- Payload: target_room
Events.GAME_OVER       -- Payload: none
Events.MINIMAP_ZONE_ENTER -- Payload: zone_id

-- 1. Subscribe
local sub_id = Events.on(Events.ROOM_CLEAR, function(room)
    print("Room cleared!", room.grid_x, room.grid_y)
end)

-- 2. Emit
Events.emit(Events.ROOM_CLEAR, current_room)

-- 3. Unsubscribe (usually handled automatically by Events.reset() on scene change)
Events.off(sub_id)
```

## Common Use Cases

| Event | Publisher | Subscriber | Purpose |
| :--- | :--- | :--- | :--- |
| `ROOM_CLEAR` | `DungeonManager` | `play.lua` | Trigger player healing (1 segment). |
| `ROOM_TRANSITION` | `CameraManager` | `Minimap` | Update minimap visited status and current room highlight. |
| `GAME_OVER` | `DeathHandlers` | `main.lua` | Switch scene to Game Over screen. |
| `MINIMAP_ZONE_*` | `Room` | `Minimap` | Handle fog-of-war updates. |

## Best Practices

- **Payloads**: Keep payloads minimal. Pass references (like `room` or `entity`) rather than copying data.
- **Cleanup**: Always ensure `Events.reset()` is called in `scene:exitedState()`.
- **Debugging**: You can log all events by wrapping `Events.emit`.
