# Towergame — Design Document

> _Source: Jake's game plan (2026-03-29)_

## One-Line Pitch

Risk of Rain 2 meets tower defense — a 2D top-down horde survival roguelike where you explore a semi-open world, fight through 5 increasingly difficult maps, defend an unmoving base with player-built towers, and discover random items, bosses, and encounters.

---

## Core Identity

**What should the player feel?**
- First: "I'm surviving against an endless swarm"
- Then: "I'm getting stronger — my setup is working"
- Then: "I can push further because my defenses hold"
- Then: "What will I find on this map?"

**Core loop (repeat per map):**
Explore → Fight enemies → Earn currency → Build towers → Defend base → Push deeper → Discover boss → Clear map → Repeat

---

## World Structure

### Maps
- **5 maps** of increasing difficulty
- Each map is a semi-open 2D top-down space
- Procedurally placed: enemies, sub-bosses, items, encounters
- **Fog of war** — areas hidden until discovered
- **Map boss** — spawns randomly somewhere on the map; must be defeated to clear the map
- Enemies spawn from map edges and path toward the base

### Base
- **Unmoving** — fixed position (center or offset)
- Has minor built-in defenses (small auto-turrets or damage aura)
- Can be upgraded through play
- If enemies reach the base and destroy it → run over (roguelike death)
- Base health as a secondary fail state alongside player death

### Exploration
- Player can venture far from base
- Towers extend the "safe zone" — player can push further knowing defenses handle the rear
- Currency earned from enemies spent at build menu
- Item pickups and upgrades found in the world

---

## Player Characters (3 to start)

Each character has:
- Unique base stats (health, speed, damage, range)
- Unique starting weapon/ability
- Unique passive bonus

### Suggested archetypes (subject to change):
1. **Tank** — High health, slow, melee, draws aggro
2. **Ranger** — Fast, ranged, lower health, early map clearing
3. **Engineer** — Turret specialist, starts with a deployable turret, synergy with tower builds

---

## Tower Defense System

### Tower Types
- **Ballistic Turret** — General purpose, moderate damage/fire rate
- **Missile Turret** — Area damage, slower fire rate
- **Slow/Energy Turret** — Slows enemies, support role
- **Wall/Barricade** — Blocks enemy pathing, buys time
- **Damage Boost Aura** — Buffs nearby towers

### Progression
- Currency earned from kills (both player and tower kills)
- Towers can be placed, upgraded (3 tiers), repaired
- New tower types unlocked between runs (meta-progression)

### Tower Placement
- Grid or freeform placement on buildable terrain
- Cost to place + cost to upgrade
- Limited slots or open placement with terrain constraints

---

## Enemy System

### Enemy Types
- **Swarmers** — Fast, weak, come in large numbers
- **Grunts** — Medium speed, medium health, standard threat
- **Tanks** — Slow, high health, high damage
- **Ranged** — Stay at distance, attack from afar
- **Boss / Map Boss** — Large, unique per map, drops valuable loot/currency
- **Sub-bosses** — Mini-bosses scattered on map, not required to clear but rewarding

### Horde Behavior
- Enemies spawn at map edges continuously
- Path toward base (basic A* or flow-field pathfinding)
- Wave intensity increases over time / per map
- Some enemies prioritize towers over base (counter-builds)

### Scaling
- Enemy health/damage scale per map
- Enemy variety increases (harder types appear)
- Boss difficulty scales with map number

---

## Roguelike Elements

### Meta-Progression (between runs)
- **Unlock tower types** — earn or purchase new turrets
- **Unlock characters** — additional starters available
- **Unlock modifiers** — map weather, enemy types, currency bonuses
- **Permanent currency** — persists across runs, spent on unlocks

### Per-Run Progression
- **Items found on map** — stat boosts, special abilities
- **Tower loadout** — decide what to build before pushing to next map
- **Build phase** — time between waves to place/upgrade towers
- **No refunds mid-wave** — forces commitment and strategy

---

## Items & Loot

### Item Rarity
- Common, Uncommon, Rare, Legendary (standard roguelike tiers)

### Item Categories
- **Offensive** — Damage boosts, attack speed, crit
- **Defensive** — Health, armor, lifesteal
- **Utility** — Speed, range, currency find
- **Special** — Unique effects, build-around items

Items drop from:
- Enemies (random chance)
- Sub-boss kills (guaranteed drop)
- Map boss kills (multiple drops)
- Treasure rooms / random map features

---

## Controls

### Keyboard & Mouse
- WASD movement
- Mouse aim + left-click attack
- Right-click or E for ability
- Number keys or hotbar for items
- B or Tab for build menu
- ESC for pause/settings

### Controller
- Left stick movement
- Right stick aim
- Right trigger attack
- Left trigger ability
- LB/RB or bumpers for items
- View/Back button for build menu
- Start for pause

---

## Visual Direction (to be finalized)

- **Style:** Sci-fi, industrial/military aesthetic
- **Perspective:** 2D top-down, camera follows player
- **Art:** Pixel art or clean vector sprites (to be decided)
- **Effects:** Muzzle flashes, projectile trails, explosion particles, screen shake
- **UI:** Minimal HUD, health bars above enemies, tower range indicators

---

## Audio (future)

- Weapon sounds, enemy death effects, ambient map music
- Boss encounter stings
- UI feedback sounds

---

## Scope Plan

### Phase 1 — Core Loop (MVP)
- One map, one character, one tower type
- Basic enemy (grunt), basic horde wave
- Base that takes damage, player who fights
- Win/lose condition (clear map boss OR base destroyed)
- Currency and simple build menu

### Phase 2 — Expand Content
- 3 characters
- 3 tower types
- More enemy variety
- Item drops
- Basic meta-progression (unlock tower types)

### Phase 3 — Polish & Expand
- 5 maps with progression
- Sub-bosses and random encounters
- Fog of war
- Full item pool
- Full tower upgrade trees
- Controller + keyboard/mouse
- Steam release

---

## Technical Stack

- **Engine:** Godot 4.x
- **Language:** GDScript
- **Target:** PC (Steam)
- **Input:** Keyboard/Mouse + Controller

---

## Technical Architecture

### Core Philosophy
- **Component-Based Architecture** — `HealthComponent`, `HitboxComponent`, `VelocityComponent` as reusable building blocks
- **Server-Authoritative** — Future-proofed with `MultiplayerSpawner` and `MultiplayerSynchronizer` (even if single-player now)
- **Global Autoloads** — `DifficultyManager` (Chronos Director), `GameState`, `PlayerManager`

---

## System 1: The Chronos Director (Difficulty Scaling)

The Director is an Autoload that tracks elapsed time and scales difficulty dynamically.

### Core Math
- **Difficulty Coefficient (C)** = `1 + (Time × Map_Multiplier)`
- **Credits earned per tick** = scales with `C`
- **Enemy HP/Damage** = base × `C`
- **Elite unlocks** at C milestones (e.g., C=2.0, C=5.0, etc.)

### Enemy Spawning
- Credits spent from a weighted table to spawn enemies
- Table includes: Swarmers (cheap), Grunts (standard), Tanks (expensive), Elites (very expensive)
- Higher C → higher chance of elite enemies spawning

---

## System 2: Player & Character Classes

### Dual Input Support
- **Keyboard/Mouse:** WASD move + Mouse aim
- **Controller:** Left stick move + Right stick aim
- Seamless switching between inputs

### 3 Classes

#### Melee (Tank)
- High health, slow movement
- Circular AOE melee attacks
- **Passive Aura:** Armor buff to nearby towers

#### Ranged
- High speed, projectile attacks
- **Passive Aura:** Range + Accuracy buff to nearby towers

#### Engineer
- Starts with a drone companion
- Faster build speed
- **Passive Aura:** Fire Rate buff to nearby towers

### Currency
- Enemies drop **Scrap** on death
- Player picks up scrap (auto-collect or click)
- Spent at build menu

---

## System 3: Tower Building & Synergy

### Placement
- Players can place towers **anywhere within a Build Radius** centered on player
- No power grid or connection required
- Ghost preview during placement

### Tower States (State Machine)
1. **Idle** — No target
2. **Targeting** — Acquired a target
3. **Attacking** — Firing
4. **Cooling Down** — Cooldown between attacks

### Synergy System
- Each tower has an `Area2D` "Synergy Zone"
- **Tower-in-zone:** Both towers gain **+10% stats** (stacking)
- **Player-in-zone:** Player gains class-specific buffs
- Visual: aura glow on synergistic towers

---

## System 4: Procedural World & Fog of War

### Map Generation
- **FastNoiseLite** generates terrain and obstacle placement
- Navigation mesh baked at runtime
- Re-bake when towers are placed (enemies pathfind around them)

### Fog of War
- `SubViewport` or `CanvasLayer` with fog texture
- Player and Towers act as "lights" — carve visible areas into fog
- Unexplored areas completely hidden
- Previously seen areas dimmed (optional)

### Navigation
- `NavigationRegion2D` with runtime-baked mesh
- Enemies pathfind toward base or player
- Tower placement triggers re-bake

---

## System 5: The Base

- Fixed at world coordinates `(0, 0)`
- **Persistent health pool** — reaching 0 ends the run
- **Basic automated turrets** — can be upgraded with Scrap
- Visual: larger structure with shield/health bar

---

## Prototype Milestones

### Milestone 1: Project Setup
- Initialize Godot 4.6 project
- Create `DifficultyManager` Autoload with time tracking and scaling math
- Create `GameState` Autoload for global state

### Milestone 2: Player Controller
- `CharacterBody2D` with dual-input support (KB/M + Controller)
- Basic health component
- Basic attack (projectile or melee)

### Milestone 3: Enemy Spawner
- Spawner using Director credits
- Basic mob AI (pathfind to base/player)
- HP/Damage scales with Difficulty Coefficient

### Milestone 4: Building System
- Build radius constraint (centered on player)
- Ghost tower placement preview
- Scrap cost deduction
- `Look At` targeting logic for turrets

### Milestone 5: Synergy Aura System
- `Area2D` detection for synergy zones
- Stat modifier stacking when towers overlap
- Class-specific player buffs from tower zones

### Milestone 6: Procedural Map
- FastNoiseLite terrain generation
- Functional `NavigationRegion2D`
- Player camera follows player

---

## Next Steps for OpenClaw

1. Initialize project structure — create Autoloads, folders, base scenes
2. Create `DifficultyManager` autoload with Chronos Director math
3. Build base `Character` class with `HealthComponent` and `CombatComponent`
4. Implement `Tower` placement logic with build radius constraint
5. Test in-editor using Godot MCP Pro bridge

_Last updated: 2026-03-29 (detailed technical spec added)_
