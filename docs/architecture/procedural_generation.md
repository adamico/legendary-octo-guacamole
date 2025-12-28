# Procedural Generation

The game uses a **Grid-Based Dungeon Generation** system inspired by *The Binding of Isaac*. The generation logic is encapsulated in `src/world/dungeon_manager.lua`.

## Core Concepts

- **Grid Layout**: Rooms are placed on a virtual grid (e.g., `0,0`, `1,0`).
- **Static Map**: The dungeon is carved into a single large Picotron `userdata` map (`256x256`), allowing for persistent world state.
- **Rule of One**: A constraint ensuring that any new room added during generation has exactly **one** neighbor, preventing 2x2 room clusters (loops are not allowed).

## Generation Phases

The generation process runs in 8 distinct phases:

### Phase 1: Start Room

- Creates a safe room at grid `0,0`.
- Tagged as `room_type = "start"`.

### Phase 2: Expansion (Random Walk)

- Iteratively adds rooms until `TARGET_ROOM_COUNT` (12) is reached.
- **Algorithm**:
    1. Pick a random "active" room.
    2. Pick a random cardinal direction.
    3. Check candidate position:
        - Must be empty.
        - Must have exactly **1 neighbor** (the parent).
    4. If valid, place new room and add to active list.
    5. If a room has no valid expansion slots, remove from active list.

### Phase 3: Specialization

- Assigns room types based on **Manhattan Distance** from the start room.
- **Leaf Nodes** (rooms with only 1 neighbor) are prioritized:
    1. **Farthest Leaf** -> **Boss Room**
    2. **2nd Farthest** -> **Treasure Room**
    3. **3rd Farthest** -> **Shop Room**
- All other non-start rooms become **Combat** rooms.
- **Difficulty Scaling**: Combat rooms are assigned a difficulty (1-3) based on distance (`floor(distance / 2) + 1`).

### Phase 4: Connection

- Iterates through all rooms and identifies neighbors.
- Populates `room.doors` table with connection data (target grid coordinates, open status).

### Phase 5: Map Carving (Walls & Floors)

1. Fills the entire map with `WALL_TILE`.
2. Iterates through all rooms and carves their **Floor** (`room:get_inner_bounds()`) using a pattern from `FloorPatterns` (e.g., checkerboard, random).

### Phase 6: Autotiling

- Scans the 1-tile margin around every room's floor.
- Applies 47-tile bitmasking logic to select the correct wall sprite (corners, vertical/horizontal edges, inner corners).
- This happens *before* obstacles are placed to ensure clean walls.

### Phase 7: Obstacle Placement

- Uses `RoomLayouts` to place features based on the room's assigned layout.
- **Features**:
  - **Pits**: Carved directly into the map (`PIT_TILE`).
  - **Rocks/Destructibles**: Spawned as entities (see [Entity Spawning](entity_spawning.md)).

### Phase 8: Corridor Carving

- Pierces the walls between connected rooms.
- Sets the door tile to `EMPTY_TILE` (transparent).
- Places decorative door frame tiles (vertical/horizontal) around the opening.

## Room Layouts & Wave Patterns

### Room Layouts (`src/world/room_layouts.lua`)

- Defines the static geometry of a room (obstacles, pits).
- Uses a **9x7 Grid System** where each cell represents a 3x2 tile block.
- **ASCII Format**:

    ```lua
    grid = {
       "R . . . R",
       ". P P P .",
       "R . . . R"
    }
    ```

### Wave Patterns (`src/world/wave_patterns.lua`)

- Defines enemy spawn positions using a similar positional DSL.
- **Legend**: `S` (Skulker), `H` (Shooter), `D` (Dasher).
- Patterns are selected based on the room's difficulty rating.
