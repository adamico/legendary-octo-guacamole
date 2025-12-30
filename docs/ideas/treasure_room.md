This is a brilliant design pivot. Transforming your "Free Loot" room into a "Challenge" room solves two problems at once: it increases the game's difficulty (crucial for a short 3-level run) and adds a "Risk vs. Reward" choice to every floor.

Since your theme is **Body Horror/Genetics** and **Health is Ammo**, we can flavor this room not as a generic arena, but as an **"Immune Response."**

Here is the design for **The Rejection Chamber**:

### 1. The Core Loop: "Inject & Survive"

Unlike standard games where you fight to *get* the chest, here you get the item **first**.

1. **The Lure:** You enter the room. It’s quiet. A powerful DNA Strand sits on a central medical chair or incubator.
2. **The Injection:** You pick up the item. You get the stat boost/mechanic **immediately**.
3. **The Rejection:** The moment the item enters your inventory, the room turns red. Alarms blare (or a heartbeat sound plays). The doors lock.
4. **The Test:** You must use your *newly mutated body* to survive 2-3 waves of enemies.
5. **The Release:** Once the enemies are dead, the doors unlock. You keep the item.

**Why this is great for MVP:**

* **Immediate Feedback:** The player instantly tests their new upgrade in a high-stress environment.
* **Resource Management:** Since shooting costs Health, the player has to calculate: *"Is this item worth the 30 HP I'm going to spend fighting these waves?"*

---

### 2. The Logic Flow (MVP Implementation)

You can likely reuse your existing Room and Enemy Spawner scripts. You just need a "Trigger" script on the item pedestal.

**State 1: Dormant**

* `RoomState = Safe`
* Doors are Open.
* Item is Interactable.

**State 2: The Trigger (OnPickup)**

* Player interacts with Pedestal.
* **Action:** Add Item to Player Inventory.
* **Action:** `DoorManager.LockAll()`
* **Action:** `Spawner.StartWaves()`

**State 3: The Purge (Combat)**

* Wave 1: Spawns 3-4 weak enemies (fodder).
* Wave 2: Spawns 1 Elite or tanky enemy.
* *Note: Since the player is spending HP to shoot, keep the enemy count lower than a normal room, but make them aggressive.*

**State 4: Stabilized**

* `If (EnemyCount == 0 && WavesComplete)`
* **Action:** Play "Room Clear" jingle.
* **Action:** `DoorManager.UnlockAll()`

---

### 3. Scaling for a 3-Level Run

Since you only have 3 levels, this room needs to evolve quickly so the player doesn't get bored.

* **Level 1 Chamber:**
* **Waves:** 2
* **Enemies:** Basic "Chasers" (simple AI).
* **Goal:** Teach the player that picking up items triggers a fight.

* **Level 2 Chamber:**
* **Waves:** 3
* **Enemies:** Introduces ranged enemies or environmental hazards (e.g., gas vents turn on).

* **Level 3 Chamber:**
* **Waves:** 3 + Mini-Boss.
* **Reward:** This room could contain a "Tier 2" item (more powerful DNA) to justify the harder fight right before the final boss.

### 4. Visual Signifiers (The Warning)

You need to make sure the player knows this isn't a free gift, or they will feel cheated the first time.

* **The Door:** Mark the door with a **Biohazard Symbol** or yellow "Quarantine" tape instead of the usual gold/treasure trim.
* **The Pedestal:** Put the item inside a glass containment tube. The "Interact" prompt should say **"BREAK GLASS"** or **"INJECT SAMPLE"** rather than just "Take."
* *This subtle language implies a consequence.*

### A quick question on "Health Ammo" balance in this room

Since the player is locked in and *forced* to spend HP to shoot enemies, there is a risk they enter the room with 20 HP, pick up the item, and then die because they don't have enough Health/Ammo to kill the wave.

**How do we prevent a soft-lock/unfair death?**

1. **Adrenaline Rush:** Picking up the item in *this specific room* heals the player for +20 HP instantly?
2. **Ammo Fodder:** The first wave of enemies are weak "grubs" that die in 1 hit and drop Health Blobs?
3. **Cruel Reality:** No safety net. If you are low HP, you should skip the item. (Very "Dark Souls" / "Binding of Isaac" style).

Which approach fits your difficulty curve?
