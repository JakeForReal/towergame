# Towergame

A 2D top-down horde survival roguelike with tower defense mechanics. Fight through waves of enemies, build and upgrade towers, and discover items as you push deeper into increasingly difficult maps.

## Core Loop

Explore → Fight enemies → Earn Scrap → Build towers → Defend your base → Push deeper → Discover bosses → Repeat

## Features

### Player Characters
Three distinct classes, each with unique stats and a passive aura that buffs nearby towers:
- **Tank** — High health, melee, armor aura for towers
- **Ranger** — Fast, ranged attacks, range/accuracy aura for towers
- **Engineer** — Turret specialist, fire rate aura for towers

### Tower System
- **Ballistic Turret** — General purpose, moderate damage and fire rate
- **Tower Synergy** — Towers in range of each other gain stacked stat bonuses
- **Player Aura** — Towers only fire when the player is within their synergy range, encouraging grouped positioning
- **3 Upgrade Tiers** — Invest Scrap to make towers stronger

### Enemy Types
- **Swarmers** — Fast, weak, come in large numbers
- **Grunts** — Standard threat, medium speed and health
- **Tanks** — Slow, high health, heavy damage
- **Ranged** — Keep distance and shoot from afar
- **Bosses** — Large, powerful enemies that drop significant Scrap

### Items & Progression
- Dropped by enemies, sub-bosses, and map bosses
- Four rarity tiers: Common, Uncommon, Rare, Legendary
- Categories: Offensive, Defensive, Utility, Special
- Between runs: unlock new tower types and characters

### Controls

**Keyboard + Mouse**
- WASD — Move
- Mouse — Aim
- Left-click — Attack
- Right-click — Ability
- B — Build menu
- ESC — Pause

**Controller**
- Left stick — Move
- Right stick — Aim
- Right trigger — Attack
- Left trigger — Ability
- View/Back — Build menu
- Start — Pause

## Technical

- **Engine:** Godot 4.6 (GL Compatibility)
- **Language:** GDScript
- **Target:** PC (Steam)
- **Architecture:** Component-based (HealthComponent, HitboxComponent, VelocityComponent, etc.)
- **Global Systems:** DifficultyManager (Chronos Director), GameState, BuildingSystem

### Project Structure
```
├── autoloads/         # Global singletons (difficulty, game state, building)
├── characters/        # Player character classes
├── components/        # Reusable components (health, hitbox, velocity, synergy)
├── enemies/           # Enemy types and AI
├── items/            # Item drops and pickups
├── maps/              # Map scenes and generation
├── scenes/            # Tower, projectile, and environment scenes
├── scripts/           # Core game scripts
├── towers/            # Tower type definitions
└── ui/                # HUD, menus, build interface
```

## Development

This is an active project built with the Godot MCP Pro bridge for rapid iteration. See `DESIGN.md` for the full technical design document.