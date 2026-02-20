# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Godot 4.6 2D platformer game written in GDScript. The game features a player character with platforming mechanics, a health system based on "cloth layers", status effects (sticky, weak), enemies, and hazards.

### Build Artifacts

The `build/` folder contains exported game binaries and distribution artifacts. This folder is excluded from version control via `.gitignore`.

## Development Commands

Godot development requires the Godot editor. There are no command-line build/test commands configured for this project.

- **Open project**: Open `project.godot` in the Godot 4.6 editor
- **Run game**: Press F5 in the Godot editor or click the play button
- **Scene editing**: Open `.tscn` files in the Godot editor

## Project Architecture

### Autoload Singletons

The project uses seven autoload singletons configured in `project.godot`:

1. **Global_settings** (`scripts/global.gd`): Legacy global gravity configuration (being phased out in favor of `GameConstants`)
2. **Playerstates** (`scripts/Playerstates.gd`): Legacy state management singleton (being phased out in favor of `PlayerManager` + `PlayerState` node)
3. **GameManager** (`scripts/autoload/game_manager.gd`): Game flow, state machine (TITLE, PLAYING, PAUSED, GAME_OVER, VICTORY), and level switching
4. **PlayerManager** (`scripts/autoload/player_manager.gd`): Player entity lifecycle, damage handling, respawn logic
5. **LevelManager** (`scripts/autoload/level_manager.gd`): Level-scoped enemy/collectible tracking, checkpoint management
6. **SaveManager** (`scripts/autoload/save_manager.gd`): Game save/load system with JSON serialization
7. **UIManager** (`scripts/autoload/ui_manager.gd`): UI panel management, HUD updates, navigation stack

### Directory Structure

```
scripts/
├── autoload/          # Global singleton managers (GameManager, PlayerManager, etc.)
├── player/            # Player mechanics module (controller, state, animation, input)
├── enemies/           # Enemy behaviors and AI module
├── hazards/           # Environmental hazards and traps module
├── ui/                # User interface panels and screens module
├── utils/             # Shared utilities and game constants
├── scene/             # Scene lifecycle and level-specific managers
├── global.gd          # Legacy global settings
└── Playerstates.gd    # Legacy player state singleton

scenes/
├── entities/          # Game entity scenes (player, enemies, hazards, projectiles)
├── Levels/            # Level scenes and tilemaps
├── UI/                # UI scenes (scaffold state)
├── title.tscn         # Main entry point (run/main_scene)
└── gameclear.tscn     # Game completion screen
```

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

**GameManager** (autoload module):
- Game state machine: `TITLE`, `PLAYING`, `PAUSED`, `GAME_OVER`, `VICTORY`
- Level loading via `load_level(level_id)` / `reload_current_level()`
- Scene path registry: `register_level(level_id, scene_path)`
- Signals: `state_changed`, `level_loaded`, `level_restarted`

**PlayerManager** (autoload module):
- Player instance registration: `register_player(player)` / `unregister_player()`
- Unified damage interface: `apply_damage(damage_data)` with `cloth_damage`, `stamina_damage`, `knockback_force`, `knockback_direction`
- Status effect application: `apply_status(status_type)` ("sticky", "weak")
- Player respawn: `respawn_player()` at `spawn_point`
- Signals: `player_spawned`, `player_died`

**Player Module** (`scripts/player/`):
- **Controller**: Physics-based CharacterBody2D movement, BOOST system (air dash), variable jump height
- **State**: Health/cloth layers, stamina, status effects (weak, sticky), damage handling
- **Animation**: Sprite animation state machine and transitions
- **Input**: Input buffering and action handling

**LevelManager** (autoload module):
- Enemy tracking: `register_enemy(enemy)` / `unregister_enemy(enemy)`
- Checkpoint system: `set_checkpoint(pos)` / `get_checkpoint()`
- Collectible tracking
- Level completion: `complete_level()` emits `level_completed`

**SaveManager** (autoload module):
- Save file: `user://save.json`
- Methods: `save_game()`, `load_game()`, `delete_save()`, `has_save()`
- Tracks: last level, checkpoint position, player state (cloth, stamina, status effects)
- Save version: 1 (with migration check)

**UIManager** (autoload module):
- Panel management: `open_panel(name, params)`, `close_panel(name)`
- UI navigation stack: `push_ui_state()`, `pop_ui_state()`
- HUD updates: `update_hud(data_type, value)` emits `hud_updated`
- Message dialogs: `show_message()`, `show_confirm()`
- Auto-connects to PlayerManager state signals

**Utils Module** (`scripts/utils/`):
- **GameConstants**: Static utility class with game-wide constants (gravity, player defaults, status durations, level mappings)
- **SignalBus**: Global signal bus for decoupled communication

### Hazard Module

**Spikes** (`scripts/hazards/`):
- Area2D trigger on player collision
- Uses `PlayerManager.apply_damage()` with `cloth_damage: 1`, `knockback_force: 1500`

**Sticky Pools** (`scripts/hazards/`):
- Applies damage + knockback via `PlayerManager.apply_damage()`
- Applies status via `PlayerManager.apply_status("sticky")`

### Code Conventions

- GDScript files use snake_case naming
- Class names use PascalCase (e.g., `PlayerState`, `GameConstants`)
- Comments are written in Chinese
- Node references use `@onready var` pattern
- Uses Godot 4's UID system for resource references (e.g., `uid://...`)
- Manager singletons follow pattern: `[Name]Manager`

### Important Notes

- The game over state disables player controls and waits for jump input to return to title screen
- Player must register with `PlayerManager` in `_ready()` and unregister in `_exit_tree()`
- Damage is always routed through `PlayerManager.apply_damage()` for consistency
- The project uses Jolt Physics engine (configured in project settings)
- Rendering uses D3D12 on Windows with Forward Plus renderer
- Legacy singletons (`Global_settings`, `Playerstates`) are being phased out in favor of the new Manager system

## Documentation

The `docs/` folder contains project documentation:

- **`analysis_20260214.md`**: Comprehensive code architecture analysis and Manager singleton refactoring proposal. Documents current system coupling issues and provides a phased refactoring plan
- **`ui_images/`**: UI design reference images

### UI Scenes

The `scenes/UI/` folder contains UI scene files (scaffold state - no art assets or functionality implemented yet).
