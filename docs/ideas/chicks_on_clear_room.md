This is the **perfect way to handle it.** Instead of throwing away one idea, you turn the "Game Design Decision" into a "Player Build Choice."

By making **Rot Rush** the default and **Sacrifice** a specific mutation, you create two completely different playstyles:

1. **The Swarm Leader:** Rushes from room to room to keep the momentum going.
2. **The Harvester:** Clears a room, "eats" the army to heal, and enters the next room calmly with full health.

Here is how to structure this for your MVP testing and implementation.

### 1. Default Behavior: "The Rot Rush"

* **Logic:**
* **On Room Clear:** Chicks keep existing.
* **On Room Exit:** Calculate offset of each chick relative to player -> Teleport them to the new room entry point near the player.

* **The Vibe:** Frantic, aggressive. You are racing against your own minions' death clock.

### 2. The Mutation: "Umbilical Retraction" (The Sacrifice)

This would be a specific DNA Strand item (e.g., "Cannibal Chromosome").

* **Logic:**
* **On Room Clear (or Exit):** All active chicks play a "pop" animation and die.
* **The Payoff:** For every chick destroyed, spawn a "Blood Glob" (or instant heal) for **+2 HP**.
* **The Upgrade:** This amount can be modified by other items (e.g., "Efficient Digestion" raises refund to +3 HP).

---

### How to Test Both (MVP Implementation)

Since you want to test which one feels better, don't hard-code it yet. Build a simple **"Behavior Manager"** script.

**The Script: `MinionManager.cs**`

```csharp
public enum MinionTransitionMode { Follow, Sacrifice }
public MinionTransitionMode currentMode = MinionTransitionMode.Follow; // Change this in Inspector to test

public void OnRoomExit() {
    // Get all active minions
    List<GameObject> minions = GetAllMinions();

    if (currentMode == MinionTransitionMode.Follow) {
        // TELEPORT LOGIC
        foreach (var minion in minions) {
            minion.transform.position = player.transform.position + randomOffset;
        }
    }
    else if (currentMode == MinionTransitionMode.Sacrifice) {
        // RECYCLE LOGIC
        int refundTotal = 0;
        foreach (var minion in minions) {
            refundTotal += 2; // Base refund value
            Destroy(minion);
        }
        player.Heal(refundTotal);
    }
}

```

### Testing Checklist

When you playtest, look for these specific feelings to decide which should be default:

**Test A: Rot Rush (Follow)**

* *Does it feel awesome to enter a room with 5 chicks already attacking?*
* *Does the screen feel too cluttered when you enter a small hallway?*
* *Do you feel pressured to rush (in a good way)?*

**Test B: Sacrifice (Recycle)**

* *Does the heal feel satisfying, or does it feel bad to lose your army?*
* *Does it make the game too easy (infinite health farming)?*
* *Does it slow the pace down too much?*

### The "Upgradable Stat" Idea

You mentioned the refund could be an upgradable stat. This is brilliant for the "Sacrifice" build.

* **Base Stat:** **Recycle Efficiency** (Starts at 0 or 20%).
* **Item:** **"Second Stomach"**
* *Effect:* Increases Recycle Efficiency. Instead of +2 HP per chick, you get +4 HP.

* **Item:** **"Bio-Fuel Converter"**
* *Effect:* Sacrificing chicks grants a temporary **Damage Boost** for the next room instead of Health.

**Recommendation:**
Start with **Rot Rush as the default**. It fits the "Isaac" style of gameplay better (building power). Make the **Sacrifice** mechanic a rare, powerful item that changes how the game is played for that run.
