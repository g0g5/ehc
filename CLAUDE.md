# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Godot 4.6 2D platformer game written in GDScript. The game features a player character with platforming mechanics, a health system based on "cloth layers", status effects (sticky, weak), and enemies.

### Build Artifacts

The `build/` folder contains exported game binaries and distribution artifacts. This folder is excluded from version control via `.gitignore`.

## Development Commands

Godot development requires the Godot editor. There are no command-line build/test commands configured for this project.

- **Open project**: Open `project.godot` in the Godot 4.6 editor
- **Run game**: Press F5 in the Godot editor or click the play button
- **Scene editing**: Open `.tscn` files in the Godot editor

## Project Architecture

### Autoload Singletons

The project uses two autoload singletons configured in `project.godot`:

1. **Global_settings** (`scripts/global.gd`): Provides global gravity configuration via `Global_settings.gravity()`
2. **Playerstates** (`scripts/Playerstates.gd`): State management singleton for player health, stamina, and status effects

### Scene Structure

- `scenes/entities/`: Player, enemies, hazards (spikes, sticky surfaces), bullets
- `scenes/Levels/`: Level scenes
- `scenes/title.tscn`: Main entry point (configured as `run/main_scene`)
- `scenes/gameclear.tscn`: Game over screen

### Physics Layers

Layer configuration from `project.godot`:
- Layer 1: BG
- Layer 2: collision
- Layer 3: player
- Layer 4: enemy
- Layer 5: enemybullets

### Input Actions

Configured in `project.godot`:
- `MOVE_LEFT`: A / Left Arrow
- `MOVE_RIGHT`: D / Right Arrow
- `MOVE_JUMP`: Space / Z

### Core Systems

**Player Controller** (`scripts/player.gd`):
- Physics-based CharacterBody2D movement
- Double jumping (configurable via `able_to_double_jump`)
- Variable jump height (jump canceling when releasing jump key)
- Knockback system via `apply_knockback(force)`
- Reads state from the `state` node (PlayerState class)

**Player State Machine** (`scripts/Playerstates.gd`):
- Health system: "cloth layers" (`current_cloth` / `max_cloth`)
- Stamina system (`current_stamina` / `max_stamina`)
- Status effects:
  - `is_weak`: Reduces knockback effectiveness, auto-recovers after 3 seconds
  - `is_sticky`: Reduces friction to 20%, auto-recovers after 5 seconds
- Signals: `cloth_broked`, `stamina_changed`, `became_weak`, `became_sticky`, `gameover`

### Code Conventions

- GDScript files use snake_case naming
- Class names use PascalCase (e.g., `PlayerState`)
- Comments are written in Chinese
- Node references use `@onready var` pattern
- Uses Godot 4's UID system for resource references (e.g., `uid://...`)

### Important Notes

- The game over state disables player controls and waits for jump input to return to title screen
- The project uses Jolt Physics engine (configured in project settings)
- Rendering uses D3D12 on Windows with Forward Plus renderer

## Documentation

The `docs/` folder contains project documentation:

- **`analysis_20260214.md`**: Comprehensive code architecture analysis and Manager singleton refactoring proposal. Documents current system coupling issues and provides a phased refactoring plan (GameManager, PlayerManager, LevelManager, etc.)
- **`mainmenu_design.md`**: Main menu UI design document outlining the menu tree structure (Start Game, Gallery, Settings, Exit), save slot selection flow, and settings options
