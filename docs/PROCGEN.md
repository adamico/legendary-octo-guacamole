# 📐 Technical Design: Isaac-Style Dungeon Generator

## Phase 1: Initialization 📍

The goal is to establish the coordinate system and the origin point.

* **Grid Setup:** Use a **Hash Map** (or Dictionary) to store room data.
  * *Key:* String coordinates `"x,y"`
  * *Value:* Room Object
* **The Origin:** Place a `START` room at `(0,0)`.
* **Seed the Queue:** Add the Start Room to an `active_list` to begin the growth process.

## Phase 2: Expansion (The Growth Loop) 🌿

This phase builds the dungeon "skeleton" using a constrained random walk.

1. **Selection:** Pull a room from the `active_list`.
2. **Directional Roll:** Choose a random cardinal direction (North, South, East, West).
3. **Neighbor Constraint:** Before placing a new room at the target `(x, y)`:
    * Verify the coordinate is empty in the Hash Map.
    * **The "Rule of One":** Ensure the target spot has exactly **one** existing neighbor (the parent). This prevents $2 \times 2$ clusters.
4. **Update:** If valid, create the room, add it to the Hash Map, and push it to the `active_list`.

## Phase 3: Specialization 💀

Once the room count is met, roles are assigned based on traversal effort.

* **Distance Mapping:** Calculate the **Manhattan Distance** from `(0,0)` for every room.
* **Boss Room Placement:** Find all "Leaf Nodes" (rooms with only 1 neighbor). Assign the `BOSS` type to the leaf node with the **highest distance** value.
* **Treasure & Shop:** Assign remaining leaf nodes to `TREASURE` or `SHOP` types, prioritizing those furthest from the start.

## Phase 4: Connection (The Door Pass) 🚪

The final pass determines where doors exist visually and logically.

* **Neighbor Lookup:** Iterate through the Hash Map.
* **Validation:** For each room at `(x, y)`, check the four adjacent coordinates.
* **Door Mapping:** If a neighbor exists at a coordinate, set the corresponding door flag (e.g., `hasNorthDoor = true`) for that room.
