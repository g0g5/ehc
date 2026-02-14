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
├── autoload/          # Global singleton scripts
│   ├── game_manager.gd
│   ├── player_manager.gd
│   ├── level_manager.gd
│   ├── save_manager.gd
│   └── ui_manager.gd
├── player/            # Player-related scripts
│   ├── player_controller.gd   # Main player CharacterBody2D
│   ├── player_state.gd        # Player state node (health, stamina, status)
│   ├── player_animation.gd    # Animation handling
│   ├── player_effects.gd      # Visual effects
│   └── player_input.gd        # Input handling
├── enemies/           # Enemy scripts
│   ├── base_enemy.gd
│   ├── white_cell.gd
│   └── enemy_bullet.gd
├── hazards/           # Hazard/trap scripts
│   ├── base_hazard.gd
│   ├── spike.gd
│   └── sticky_pool.gd
├── ui/                # UI panel scripts
│   ├── title_screen.gd
│   ├── hud.gd
│   ├── pause_menu.gd
│   ├── settings_menu.gd
│   └── game_clear.gd
├── utils/             # Utilities and constants
│   ├── constants.gd   # GameConstants class
│   └── signal_bus.gd  # Global signal bus
├── scene/             # Scene management
│   ├── scene_manager.gd
│   └── levels/
│       └── level_01_manager.gd
├── global.gd          # Legacy global settings
└── Playerstates.gd    # Legacy player state singleton
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

**GameManager** (`scripts/autoload/game_manager.gd`):
- Game state machine: `TITLE`, `PLAYING`, `PAUSED`, `GAME_OVER`, `VICTORY`
- Level loading via `load_level(level_id)` / `reload_current_level()`
- Scene path registry: `register_level(level_id, scene_path)`
- Signals: `state_changed`, `level_loaded`, `level_restarted`

**PlayerManager** (`scripts/autoload/player_manager.gd`):
- Player instance registration: `register_player(player)` / `unregister_player()`
- Unified damage interface: `apply_damage(damage_data)` with `cloth_damage`, `stamina_damage`, `knockback_force`, `knockback_direction`
- Status effect application: `apply_status(status_type)` ("sticky", "weak")
- Player respawn: `respawn_player()` at `spawn_point`
- Signals: `player_spawned`, `player_died`

**Player Controller** (`scripts/player/player_controller.gd`):
- Physics-based CharacterBody2D movement
- BOOST system (horizontal/vertical air dash when jump pressed in air)
- Variable jump height (jump canceling when releasing jump key)
- Knockback via `apply_knockback(force, direction)`
- Reads state from `$state` node (PlayerState class)
- Registers with PlayerManager on `_ready()`

**Player State** (`scripts/player/player_state.gd`):
- Health system: "cloth layers" (`current_cloth` / `max_cloth`)
- Stamina system (`current_stamina` / `max_stamina`)
- Status effects:
  - `is_weak`: Reduces knockback effectiveness (3 second recovery)
  - `is_sticky`: Reduces friction to 20% (5 second recovery)
- Damage handling: `take_damage(cloth, stamina, knockback) -> final_knockback`
- Signals: `cloth_broked`, `stamina_changed`, `became_weak`, `became_sticky`, `gameover`

**LevelManager** (`scripts/autoload/level_manager.gd`):
- Enemy tracking: `register_enemy(enemy)` / `unregister_enemy(enemy)`
- Checkpoint system: `set_checkpoint(pos)` / `get_checkpoint()`
- Collectible tracking
- Level completion: `complete_level()` emits `level_completed`

**SaveManager** (`scripts/autoload/save_manager.gd`):
- Save file: `user://save.json`
- Methods: `save_game()`, `load_game()`, `delete_save()`, `has_save()`
- Tracks: last level, checkpoint position, player state (cloth, stamina, status effects)
- Save version: 1 (with migration check)

**UIManager** (`scripts/autoload/ui_manager.gd`):
- Panel management: `open_panel(name, params)`, `close_panel(name)`
- UI navigation stack: `push_ui_state()`, `pop_ui_state()`
- HUD updates: `update_hud(data_type, value)` emits `hud_updated`
- Message dialogs: `show_message()`, `show_confirm()`
- Auto-connects to PlayerManager state signals

**GameConstants** (`scripts/utils/constants.gd`):
- Static utility class with game-wide constants
- `GRAVITY_VECTOR`: Vector2(0, 3000)
- Player defaults: `PLAYER_MAX_CLOTH`, `PLAYER_MAX_STAMINA`
- Status durations: `WEAK_DURATION` (3s), `STICKY_DURATION` (5s)
- Level scene path mappings

### Hazard System

**Spike** (`scripts/hazards/spike.gd`):
- Area2D trigger on player collision
- Uses `PlayerManager.apply_damage()` with `cloth_damage: 1`, `knockback_force: 1500`

**Sticky Pool** (`scripts/hazards/sticky_pool.gd`):
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
- **`mainmenu_design.md`**: Main menu UI design document outlining the menu tree structure (Start Game, Gallery, Settings, Exit), save slot selection flow, and settings options
