# Combat Balance Research: Action Roguelikes

Research on how successful action roguelikes balance combat, enemy HP, and room density to inform our design decisions.

---

## The Binding of Isaac: Rebirth

**Player Health System:**
- **Starting HP**: 6 hearts (= 12 HP, half hearts count)
- **Damage per enemy hit**: 0.5-1 heart typically (contact damage)
- **Hits to kill player**: ~6-12 hits at start

**Enemy HP (Early Floors):**
- **Weak enemies** (Flies, Spiders): 3-5 HP → **1 shot** with base tear damage (3.5)
- **Standard enemies** (Walking hosts, Globins): 10-20 HP → **3-6 shots**
- **Tanky enemies** (Knights, Fatties): 30-50 HP → **9-14 shots**
- **Mini-bosses**: 50-100 HP → **14-28 shots**

**Room Density:**
- **Early rooms**: 3-8 enemies
- **Medium rooms**: 6-12 enemies
- **Large rooms**: 10-15+ enemies
- **Ratio**: ~60% weak, 30% standard, 10% tanky

**Fire Rate & DPS:**
- Base: 15 tears/sec (0.067s delay)
- Base DPS: ~52.5 damage/sec
- **Time to clear room**: 10-30 seconds

**Key Insight:** Player can 1-shot most enemies but faces **volume threat**. Health is precious (costs pickups to restore).

---

## Enter the Gungeon

**Player Health System:**
- **Starting HP**: 3 armor (6 hits with starting gun dodge roll)
- **Damage per hit**: 0.5-1 armor (contact or projectile)
- **Effective hits to kill**: ~6-10 (with dodge rolling)

**Enemy HP (Floor 1):**
- **Weak enemies** (Bullet Kin): 15 HP → **5-8 shots** (starting pistol ~2 damage)
- **Standard enemies** (Shotgun Kin): 25-40 HP → **10-15 shots**
- **Elites** (Lead Maiden): 80-120 HP → **30-50 shots**
- **Room bosses**: 200-400 HP → **100-200 shots**

**Room Density:**
- **Small rooms**: 2-4 enemies
- **Medium rooms**: 4-8 enemies
- **Large rooms**: 8-12 enemies
- **Emphasis**: Fewer, tougher enemies with complex patterns

**Fire Rate & DPS:**
- Starting pistol: 4 rounds/sec
- DPS: ~8 damage/sec
- **Time to clear room**: 15-40 seconds

**Key Insight:** Emphasis on **dodging** over tanking. Enemies are bullet sponges to encourage weapon switching and accuracy.

---

## Nuclear Throne

**Player Health System:**
- **Starting HP**: 10 HP (varies by character)
- **Damage per hit**: 1-4 HP (most projectiles = 2 HP)
- **Hits to kill**: ~3-5 hits (very fragile!)

**Enemy HP (Early Areas):**
- **Weak enemies** (Bandits, Maggots): 3-6 HP → **1-2 shots**
- **Standard enemies** (Big Dog, Scorpions): 8-15 HP → **2-4 shots**
- **Tanky enemies** (Big Bandit): 20-30 HP → **5-8 shots**
- **Bosses**: 50-150 HP → **12-40 shots**

**Room Density:**
- **Early rooms**: 5-10 enemies
- **Mid rooms**: 8-15 enemies
- **Late rooms**: 12-20+ enemies
- **Characterization**: Constant, overwhelming pressure

**Fire Rate & DPS:**
- Starting weapons: 3-6 shots/sec
- DPS: ~6-12 damage/sec
- **Time to clear room**: 5-15 seconds (fast-paced!)

**Key Insight:** **High lethality on both sides**. Player dies fast, enemies die fast. Constant aggression rewarded (HP drops on kill).

---

## Hades

**Player Health System:**
- **Starting HP**: 50 HP
- **Damage per hit**: 5-15 HP (varies wildly by enemy/attack)
- **Hits to kill**: ~5-10 hits

**Enemy HP (Tartarus):**
- **Weak enemies** (Numbskulls, Witches): 40-60 HP → **4-8 hits**
- **Standard enemies** (Skullcrusher, Brimstone): 100-200 HP → **10-20 hits**
- **Elites** (Wretches, Champions): 300-600 HP → **30-60 hits**
- **Mini-bosses**: 800-1500 HP → **80-150 hits**

**Room Density:**
- **Small encounters**: 3-6 enemies
- **Medium encounters**: 6-12 enemies
- **Large encounters**: 10-18 enemies
- **Waves**: Multiple spawns over time

**Attack Speed & DPS:**
- Base sword: ~1.5 attacks/sec, 20 damage = 30 DPS
- **Time to clear room**: 20-60 seconds

**Key Insight:** **Sustain-focused**. Generous HP, frequent healing, emphasis on learning patterns. Less punishing than other roguelikes.

---

## Dead Cells

**Player Health System:**
- **Starting HP**: ~100 HP (with flask for +50% healing)
- **Damage per hit**: 10-30 HP
- **Hits to kill**: ~5-10 hits

**Enemy HP (Promenade):**
- **Weak enemies** (Zombies, Grenadiers): 50-80 HP → **3-6 hits** (starting sword ~15 damage)
- **Standard enemies** (Shieldbearers, Bats): 120-200 HP → **8-13 hits**
- **Elites**: 400-800 HP → **25-50 hits**

**Room Density:**
- **Small rooms**: 2-5 enemies
- **Medium rooms**: 5-10 enemies
- **Large rooms**: 8-15 enemies
- **Progressive**: Rooms get denser as you progress

**Attack Speed & DPS:**
- Base weapons: 1-2 attacks/sec
- DPS: ~20-30 damage/sec
- **Time to clear room**: 10-30 seconds

**Key Insight:** **Methodical combat**. Encourages combos and crowd control. Health management is key (limited healing).

---

## Comparative Analysis

| Game | Player HP | Hits to Kill Player | Weak Enemy HP | Standard Enemy HP | Enemies/Room | TTK Room (avg) |
|------|-----------|---------------------|---------------|-------------------|--------------|----------------|
| **Isaac** | 12 | 6-12 | 3-5 (1 shot) | 10-20 (3-6 shots) | 6-12 | 15-25s |
| **Gungeon** | 6 | 6-10 | 15 (5-8 shots) | 25-40 (10-15 shots) | 4-8 | 20-40s |
| **Nuclear** | 10 | 3-5 | 3-6 (1-2 shots) | 8-15 (2-4 shots) | 8-15 | 5-15s |
| **Hades** | 50 | 5-10 | 40-60 (4-8 hits) | 100-200 (10-20 hits) | 6-12 | 30-50s |
| **Dead Cells** | 100 | 5-10 | 50-80 (3-6 hits) | 120-200 (8-13 hits) | 5-10 | 15-30s |

---

## Design Patterns

### 1. **The "Glass Cannon" Pattern** (Nuclear Throne)
- Low player HP (10)
- Low enemy HP (3-15)
- High density (8-15 enemies)
- **Feel**: Frantic, reflex-based, high skill ceiling

### 2. **The "Volume Shooter" Pattern** (Isaac)
- High RoF, low damage per shot
- Enemies die in 1-6 shots
- Medium-high density
- **Feel**: Satisfying mowing down hordes

### 3. **The "Tactical Shooter" Pattern** (Gungeon)
- Low RoF, moderate damage
- Enemies are bullet sponges
- Low-medium density, focus on dodging
- **Feel**: Methodical, pattern-based

### 4. **The "Sustain Brawler" Pattern** (Hades)
- High HP pools on both sides
- Frequent healing opportunities
- Medium density with waves
- **Feel**: Forgiving, learning-focused

---

## Recommendations for Our Game

Given our **health-as-ammo** mechanic, we need to balance:

### Option A: "Expensive Shots, Cheap Enemies" (Recommended)
```
Player: 100 HP = 5 shots
Enemy (weak): 10 HP → 1 shot to kill
Enemy (standard): 20 HP → 2 shots to kill
Room density: 4-8 enemies
```

**Rationale:**
- Each shot costs 20 HP, so enemies should die quickly (1-2 shots)
- Player recovers 16 HP per pickup → Net cost = 4 HP per enemy killed (if 1 enemy = 1 pickup)
- **Economy**: Kill 5 enemies = spend 100 HP, collect 5 pickups = recover 80 HP → Net -20 HP per room
- Forces strategic regen or cautious play

### Option B: "Medium Shots, Medium Enemies"
```
Player: 100 HP = 5 shots
Projectile damage: 15 HP
Enemy (weak): 15 HP → 1 shot
Enemy (standard): 30 HP → 2 shots
Room density: 3-6 enemies
```

**Rationale:**
- Cleaner numbers (enemies = exact multiples of damage)
- Lower density compensates for limited ammo
- **Economy**: Tighter, each miss is costly

### Option C: "Projectile Doesn't Kill, Contact Does"
```
Player: 100 HP = 5 shots
Projectile damage: 5 HP (stuns/slows enemy)
Contact damage to enemy: Player deals 20 HP on touch
Enemy HP: 20-40 HP
```

**Rationale:**
- Projectiles used for crowd control, not killing
- Encourages aggressive melee play
- Unique twist on the formula
- **Economy**: Pickups come from contact kills, not projectile kills

---

## Proposed MVP Values

**Player:**
- HP: 100 (5 shots)
- Shot cost: 20 HP
- Projectile damage: 10 HP
- Contact damage taken: 10 HP (0.5 shots worth)
- Regen: 5 HP/sec after 3s (1 shot every 12s of safety)

**Enemy (Basic "Skulker"):**
- HP: 20 HP (2 shots to kill)
- Movement: Slow chase (0.5 speed vs player 1.0)
- Contact damage: 10 HP
- Drop: 50% chance for HP pickup (16 HP)

**Room Density:**
- Early rooms: 3-5 enemies
- Mid rooms: 5-8 enemies
- Hard rooms: 8-12 enemies

**Economy Check:**
```
5 enemies × 2 shots = 10 shots needed = 200 HP spent
Player has 100 HP = can kill 2.5 enemies before going broke
Must collect 3 pickups to continue (48 HP recovered)
If all 5 enemies drop pickups: 80 HP recovered
Net cost per room: -120 HP (need regen or get better at dodging)
```

This creates **tension**: You can't kill entire rooms without collecting, and not all enemies drop pickups. Regen becomes essential for sustain between encounters.

---

## Questions to Answer via Playtesting

1. **Should projectiles one-shot or two-shot weak enemies?**
   - One-shot: More satisfying, faster rooms
   - Two-shot: More tension, ammo management matters more

2. **Should all enemies drop pickups, or only some?**
   - All: Generous, sustain-focused (like Nuclear Throne)
   - Some (50%): Tighter economy, regen essential

3. **Should regen be enabled in combat, or only out of combat?**
   - In combat: More forgiving
   - Out of combat only: Encourages clearing rooms quickly

4. **Should contact damage = shot cost, or less/more?**
   - Equal (20 HP): Taking a hit = wasting a shot, very punishing
   - Less (10 HP): More forgiving, allows aggressive play
   - More (30 HP): Glass cannon, incentivizes perfect play
