# Pizak

**A Binding of Isaac-inspired dungeon crawler where your health is your ammunition.**

## About the Game

Pizak flips the traditional dungeon crawler formula on its head. Every shot costs 5 HP—a resource you must manage carefully. But eggs are unpredictable: some are duds that barely scratch enemies, others hatch into allies that fight alongside you, and rare ones leech health back to you. Master the chaos of your ammunition and discover the art of measured aggression in this roguelike dungeon crawler.

## Core Mechanics

- **Twin-Stick Controls** – Move with the second D-pad, aim with the first D-pad, fire with O button
- **Health as Ammo** – Each egg projectile costs 5 HP (you start with 100 HP, so spend wisely)
- **Three-Outcome Egg System** – Each fired egg has different results: Duds (50% - 3 damage), Hatching Eggs (35% - spawn a Chick minion), or Leeches (15% - deal 5 damage and drop health)
- **Vampiric Melee Attack** – When critically low on health (≤20 HP), unleash a close-range attack that restores health on hit
- **XP & Leveling** – Defeat enemies to earn XP. Reach level 2 at 50 XP, then scale linearly. Each level increases your combat stats
- **Mutation System** – Unlock powerful mutations that modify your eggs, damage, range, and more. Build your own playstyle with stat-altering effects
- **Positioning Matters** – Fight near walls to quickly reclaim missed shots, or brave open spaces for greater risk
- **Bombs & Explosives** – Press X to place destructive bombs that spawn from your inventory

## Features

- ✨ **Procedural Dungeon Generation** – No two runs are alike, with carve-based room layouts featuring rocks, obstacles, pits, chests, and treasure vaults
- 🗺️ **Isaac-Style Minimap** – Complete with fog of war, smart rotation (flees the player), and special location markers (Boss, Treasure)
- ⚔️ **Smart Enemy AI** – Five distinct enemy types with FSM-based behavior: Skulker (intelligent pursuit), Shooter (ranged with vision range), Dasher (aggressive charging), Skull (invincible pressure mechanic), Boss (multi-phase with shooting and summoning), and tactical wave formations
- 🐣 **Minion System** – Fire eggs that hatch into Chicks—intelligent minions with A* pathfinding that seek food and chase enemies alongside you
- 💥 **Satisfying Feedback** – Floating damage/heal numbers (red/green), particle effects with batch optimization, visual screen shake, and enemy flash effects
- 🎮 **Smooth Twin-Stick Gameplay** – Responsive aiming with dashed trajectory preview and frame-perfect input
- 📈 **XP & Leveling System** – Defeat enemies to gain XP and level up (50 XP to reach level 2, scales linearly)
- ⚡ **Advanced Physics** – Z-axis elevation simulation for arcing projectiles, friction-based knockback decay, and spatial collision detection with bitmask filtering
- 💡 **Dynamic Lighting & Shadows** – Palette-swapping spotlight system centered on the player for immersive atmosphere

## Strategic Depth

Pizak isn't just about reflexes—it's about strategy and resource management:

- **Accuracy is paramount** – Every projectile is a resource commitment. Wasting ammunition means losing healing opportunities
- **Build Variety** – Mutations create unique playstyles. Will you boost damage, range, fire rate, or unlock special egg effects? No two runs are identical
- **Positioning is crucial** – Tight corridors and walls can trap you, while open spaces make Chick minions harder to manage
- **Tension is constant** – The health cost of every attack creates meaningful decision-making. Do you fire now or play it safe?
- **Skull Pressure System** – Lingering in cleared rooms too long spawns an invincible pursuer that forces you to progress
- **Minion Synergy** – Deploy Chick minions to create diversions, split enemy attention, and wear down tougher foes with coordinated attacks
- **Boss Challenge** – Face a formidable boss deep in the dungeon with unique attack patterns and multiple phases. Learn its rhythm and adapt your strategy to survive

## Built With

Pizak is built with **Lua on Picotron**, featuring:

- **Entity-Component-System (ECS) Architecture** – Efficient, data-driven entity management using the eggs library
- **Advanced Collision System** – Spatial hashing with bitmask-based filtering for hundreds of simultaneous interactions
- **Pub/Sub Event Bus** – Decoupled communication system for UI, logic, and game state
- **Type Object Pattern** – Data-driven configuration for enemies, projectiles, and pickups
- **State Machines** – FSM-based AI for intelligent, emotional enemy behaviors
- **Batch-Optimized Rendering** – Y-sorted 2.5D visual pipeline with lighting and shadow systems

**Are you ready to spend your life to save it? Enter the dungeon and discover what fate awaits in Pizak.**
