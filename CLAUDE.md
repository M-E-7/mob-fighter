# mob-fighter — Claude Code Guidelines

This file is the always-loaded entry point: project overview, architecture, the universal coding conventions, and the master **Hard-Won Gotchas** list. Deep per-subsystem detail lives in `docs/claude-*.md` — read the matching file (see **Subsystem Docs** below) before working in that area.

## Project Overview

2D top-down shooter built in Godot 4.6 (Forward Plus, Direct3D 12), being built out into a run-based **roguelike** (theme: an *antivirus ship* purging malware through a computer's **sectors**; the run loop, Sandbox shop, Daemon modifiers, and meta-progression are specced in `docs/claude-roguelike.md`).  
Main scene: `Levels/MainMenu/MainMenu.tscn` → loads `Levels/LevelPrototype/basic_level.tscn`  
Global autoloads: `EventBus` (`Autoloads/event_bus.gd`), `GameConfig` (`Autoloads/game_config.gd`), `MusicManager` (`Autoloads/music_manager.gd`), `AdvancedConfig` (`Autoloads/advanced_config.gd`), `RunState` (`Autoloads/run_state.gd`). *Planned (roguelike roadmap, see `docs/claude-roguelike.md`):* `MetaProgression` (`Autoloads/meta_progression.gd`)  
Window: 1920×1080, canvas stretch.

---

## Architecture

The project uses **component-based composition**:

- `LivingEntity` (CharacterBody2D) is the base for all living entities. It holds typed `@export` references to component nodes and delegates all behavior to them in `_physics_process`.
- Components are `Node` children of the entity scene, each responsible for one concern (movement, health, input, shooting, etc.).
- `EventBus` is the only communication channel for cross-system events. No direct node-to-node signal coupling for global events.
- `GameConfig` is a session-wide autoload. It holds `player_count`, HUD visibility toggles (`hud_show_*`, `music_visuals_enabled`, `show_music_visualizer`), camera settings (`camera_relative_mode`, `mouse_sensitivity`, `camera_smoothing`, `camera_look_ahead`, `camera_look_ahead_smoothing`), and end-of-run result fields (`result_kills_*`, `result_currency`, `result_survival_time`). HUD toggles and camera settings are written from the Settings scene; `camera_relative_mode` can also be toggled in-game with the X key (`toggle_camera_mode` action in `basic_level._toggle_camera_mode()`). Result fields are written by `basic_level.gd` just before showing the end screen — **as of P4**, `result_kills_*` and `result_survival_time` hold **run-cumulative** totals sourced from `RunState.run_kills`/`run_time` (not per-sector HUD values). Never write gameplay state to `GameConfig` mid-run.
- `AdvancedConfig` is a no-`class_name` autoload that exposes every value-type `@export` variable from all components and entities as runtime-overridable settings (see `docs/claude-config.md`). It connects to `SceneTree.node_added` in `_ready()` and applies stored overrides to each node before its own `_ready()` runs, so cached values see the correct overridden values. Never add `class_name AdvancedConfig` — same reason as `MusicManager`.
- **Roguelike run loop (P1–P6 and P11 built; P7–P10 planned — see `docs/claude-roguelike.md`):** a run is a sequence of **sectors** (`basic_level.tscn` reused, parameterized by `RunState.current_level`) — collect **Bits** (currency) → meet the sector objective → an **ExitPort** spawns → the **Sandbox** shop → next sector → final rogue-AI boss → win. State splits across three tiers: `GameConfig` (settings + results), `RunState` (one run, wiped on `reset()`), `MetaProgression` (persistent `user://` unlocks). **Built (P1):** `RunState` is live and is the *sole* subscriber to `EventBus.xp_collected` — it banks each orb into `RunState.currency` and emits `EventBus.currency_changed(total)`; the in-run level-up is gone and `XPComponent` is now a pure stat-upgrade holder. **Built (P2):** a `LevelObjectiveComponent` drives a per-sector **kill-quota** objective (keyed off `current_level`, counts `"enemy"`-group deaths) and spawns an **`ExitPort`** `Area2D` on completion; entering it defers a scene change to the **Sandbox** (a P2 stub → MainMenu). The HUD shows objective progress (`hud_show_objective`); objective/port tunables are exposed via `@export` + `AdvancedConfig` (*Sector Objective* / *Exit Port* groups). **Built (P3):** the full Sandbox shop (`Levels/Sandbox/Sandbox.tscn`). **Built (P4):** entering the ExitPort on the final sector (`current_level >= MAX_LEVELS`) shows `WinUI` (skips the last shop); death ends the run and Game Over's PLAY AGAIN resets `RunState` for a fresh run; `RunState.run_kills`/`run_time` accumulate stats across all sectors. **Built (P5):** difficulty scales linearly sector 1→10 across four levers (spawner rate/cap, enemy HP/damage/speed, arena size/density, kill quota); curve driven by `RunState.sector_t()` (0→1) × `RunState.threat_factor()` (P9 Threat-Level stub, default ×1.0); all knobs tunable in Advanced Settings; debug "Reload as Sector N" added to DebugMenuUI. **Built (P6):** bosses — `LevelObjectiveComponent` enters boss mode on sectors 5 (miniboss "ROOTKIT", purple) and 10 (final boss "ROGUE AI — SYSTEM CORE", red); stops normal spawner, spawns a `Boss` entity (`Entities/Boss/`) driven by `BossAIComponent` (radial/spread/spiral attack patterns, `preferred_distance` steering); HP scales via `lerpf(boss_health, boss_health_max, sector_t())`; `BossHealthBar` (`UI/`) shows a name-card banner intro + top-center HP bar; ExitPort spawns at the boss's death position; final boss death → ExitPort → existing win path. Debug "Spawn Boss" in DebugMenuUI. **Built (P11):** Alt-toggled `DebugMenuUI` (`UI/DebugMenuUI.tscn`) pauses the game and exposes live editing of Bits, player health, objective progress/requirement, god-mode, quick-grant Bits, complete-objective-now, kill-all-enemies, spawn boss, force-win, force-game-over, sector jump, and a live info readout (FPS/enemies/sector/position). **Planned:** Daemons (P7), save layer (P8), `MetaProgression` (P9). The new autoloads are no-`class_name`.
- The arena is procedurally generated by `ProcGenLevelComponent`; enemies are spawned by `EnemySpawnerComponent`.
- `MusicManager` is a no-`class_name` autoload (the singleton name IS the global identifier — adding `class_name` causes a conflict). It creates the `MusicAnalysis` audio bus and spectrum analyzer at runtime, exposes smoothed floats (`bass`, `mid`, `treble`, `onset_energy`, `beat_cooldown_remaining`), emits `EventBus.beat_detected` via onset detection, and is the sole writer of the `mus_*` shader globals (see `docs/claude-music.md`). Call `MusicManager.start()` / `MusicManager.stop()` from the level, never from `_ready()`.
- `PlayerInputComponent` smoothly rotates the entity toward the mouse each frame, capped by `turn_speed` (rad/s, `@export` on the component). After rotating, `aim_direction` is re-derived from `entity.rotation` — **not** from the raw mouse vector — so bullets always travel in the direction the ship is visually facing. Do not read `aim_direction` as a mouse direction; it reflects the ship's current heading. In relative camera mode, the component uses `relative_camera_angle` (a float set by `RelativeCameraComponent` each frame) as the ship's target angle instead of computing from mouse position.
- Movement is **ship-relative**: `move_vector` from `PlayerInputComponent` is a local-space vector where `y: -1` = forward (W), `y: +1` = backward (S), `x: -1` = strafe left (A), `x: +1` = strafe right (D). `MovementComponent` converts this to world-space using `entity.rotation` each frame. Space is a turbo that always adds the facing direction to the movement vector and raises the speed cap to `entity.max_speed * entity.turbo_speed_multiplier`.
- Each player ship is a self-contained **ship model scene** (`ShipModel` root, `Entities/Player/Ships/`). It owns the `SpriteDisplay`, `NeonShaderComponent`, and `ThrusterComponent` (with its `ThrusterSocket` children). The ship scene is a child of the `Player` entity. `Player._ready()` calls `ship.setup(self)` to propagate the entity reference into the ship's sub-components after the scene tree is ready. To swap ships, replace the `PlayerShip` child instance in `player.tscn` (see `docs/claude-ships.md`).

---

## Subsystem Docs

Read the matching file before working in that area — this root file carries only the imperatives; the "why" and the how-to live in these:

| Working on…                                                  | Read |
|--------------------------------------------------------------|------|
| Creating a component or entity                               | [docs/claude-components.md](docs/claude-components.md) |
| Bloom/glow, shaders, particles, impact & death FX, perf      | [docs/claude-rendering.md](docs/claude-rendering.md)   |
| Music analysis, beat detection, reactive visuals, walls, bg  | [docs/claude-music.md](docs/claude-music.md)           |
| Player ship visuals, thrusters, neon shader, adding a ship   | [docs/claude-ships.md](docs/claude-ships.md)           |
| Camera (fixed/relative, look-ahead, screen shake)            | [docs/claude-camera.md](docs/claude-camera.md)         |
| Advanced Settings / AdvancedConfig / tunable properties      | [docs/claude-config.md](docs/claude-config.md)         |
| Menus, HUD theme, pause system, debug menu (P11)             | [docs/claude-ui.md](docs/claude-ui.md)                 |
| Roguelike run loop, currency, shop, Daemons, meta-progression| [docs/claude-roguelike.md](docs/claude-roguelike.md)   |
| Pending tasks, roadmap, backlog                              | [docs/todo.md](docs/todo.md)                           |

---

## Directory Conventions

```
Components/
  Scripts/        ← component .gd files (snake_case filenames)
  Shaders/        ← all .gdshader files
  *.tscn          ← component scene files (PascalCase filenames)
Effects/
  Scripts/        ← one-shot effect .gd files (snake_case)
  *.tscn          ← effect scenes (EnemyDeathFX.tscn, BulletImpactFX.tscn, MuzzleFlashFX.tscn)
Entities/
  <EntityName>/   ← one folder per entity; contains both .gd and .tscn
  Player/
    Ships/        ← one scene per ship model (PlayerShip.tscn, etc.)
Autoloads/        ← global singletons only
Levels/           ← level scenes and their controller scripts
Resources/        ← shared .tres resources (neon_environment.tres)
UI/               ← standalone UI scenes (HUD, LevelUpUI, GameOverUI, FloatingTextManager, etc.)
  Themes/         ← shared Theme resources (neon_theme.tres)
docs/             ← per-subsystem Claude guidelines (claude-*.md), read on demand
```

Effects are **not** components: they have no `entity` export, are spawned by `FXManagerComponent`, play once, and free themselves (particle `finished` signal + a `SceneTreeTimer` fallback).

---

## Naming Conventions

| Thing | Convention | Example |
|---|---|---|
| Script files | snake_case | `health_component.gd` |
| Scene files | PascalCase | `HealthComponent.tscn` |
| `class_name` | PascalCase | `HealthComponent` |
| Variables | snake_case | `current_health` |
| Private variables | `_snake_case` | `_recalc_timer` |
| Constants | SCREAMING_SNAKE_CASE | `RECALC_INTERVAL` |
| Functions | snake_case | `take_damage()` |
| Signal handlers | `_on_<signal_name>` | `_on_entity_died()` |

---

## Script Structure

Declarations must appear in this order:

1. `extends`
2. `class_name`
3. Local signals (rare — prefer EventBus)
4. `@export_group` + `@export` variables
5. Regular member variables (public first, then private `_`)
6. Constants
7. `_ready()`
8. `_process()` / `_physics_process()`
9. Public methods
10. Private / helper methods (prefixed `_`)

See `docs/claude-components.md` for the full component/entity authoring guide (script template, wiring, node layouts).

---

## EventBus Rules

- All cross-system signals live exclusively in `Autoloads/event_bus.gd`.
- Signal naming: `noun_verb` — e.g., `entity_died`, `health_changed`.
- Always pass the entity as the first argument so listeners can filter by identity.
- Emit from the component that owns the state change; subscribe in `_ready()`:

```gdscript
func _ready() -> void:
    EventBus.entity_died.connect(_on_entity_died)

func _on_entity_died(entity: LivingEntity) -> void:
    if entity != self.entity:
        return
    # handle death
```

---

## Type Hints

All function parameters and return types must be explicitly typed:

```gdscript
func take_damage(amount: float) -> void:
func move(direction: Vector2, delta: float) -> void:
var bullets: Array[Bullet] = []
```

---

## Groups

If a node needs to be located by others at runtime, register it in `_ready()`:

```gdscript
func _ready() -> void:
    add_to_group("proc_gen")
```

Find it elsewhere with:

```gdscript
get_tree().get_first_node_in_group("proc_gen") as ProcGenLevelComponent
```

---

## Deferred Calls

Use `.call_deferred()` for scene-tree operations that happen during `_ready()`:

```gdscript
generate.call_deferred()
get_parent().add_child.call_deferred(some_node)
```

---

## Comments

- Only comment the **why**, never the **what**.
- One short line maximum. No docstrings, no multi-line comment blocks.
- Complex algorithms (pathfinding, noise, greedy rectangle merging) deserve a brief rationale comment.

---

## Hard-Won Gotchas

The load-critical rules — these stay in root because the failure mode of each is a silent regression. The full rationale for many lives in the linked `docs/claude-*.md`; the imperative is here so it is always in context.

- Do not put game logic in `LivingEntity` — delegate to a component.
- Do not use hard-coded `get_node("../../SomePath")` — use `@export` references.
- Do not connect signals directly between nodes for global events — use `EventBus`.
- Do not omit type hints.
- Do not use `@onready` when an `@export` reference set in the inspector is cleaner.
- Do not skip the scene file for a component — every component has both a `.gd` and a `.tscn`. *(see docs/claude-components.md)*
- Do not use a plain `Node` root for any component that has `Node2D` children — use `Node2D`. A `Node` root silently orphans visual children from the canvas item tree, making them invisible.
- Do not inject `ParticleProcessMaterial` into `GPUParticles2D` at runtime (`_ready()`). Define it as a `[sub_resource]` in the `.tscn` file — runtime injection is silently ignored by the rendering server. *(see docs/claude-rendering.md)*
- Do not write `Color(r, g, b)` in `.tscn` files — the resource text parser requires all 4 components: `Color(r, g, b, a)`. Three-component literals cause a parse error at load time and `load()`/`preload()` returns null. GDScript accepts 3-component Colors fine; the restriction is `.tscn` only.
- Do not use `material_override` on `MeshInstance2D` — that property belongs to `MeshInstance3D`. The correct property is `material` (inherited from `CanvasItem`). Using the wrong name silently does nothing and the mesh renders plain white.
- Gameplay SubViewports are **LDR** — channel values clamp at 1.0, so there is no "overbright bloom fuel" in the world. Drive the neon look with saturated colors and the `screen_glow` bright-pass threshold, not values > 1.0. Overbright `font_color`/`modulate` (1.0–3.0) only blooms in the **root viewport** (menus/HUD), which is HDR. *(see docs/claude-rendering.md)*
- Do not implement `_input` or `_unhandled_input` on a `PROCESS_MODE_ALWAYS` node without a `if not visible: return` guard. Hidden nodes with `PROCESS_MODE_ALWAYS` still receive input events, silently consuming them from nodes below in the stack. *(see docs/claude-ui.md)*
- Do not call `get_tree().change_scene_to_file()` while `get_tree().paused` is true — the new scene will not load. Always unpause first.
- Do not free collision objects from inside a physics callback — calling `change_scene_to_file()` (or any scene teardown) directly from `Area2D.body_entered`/`area_entered` removes `CollisionObject2D`s mid-physics-step, which Godot forbids and corrupts physics state. Defer it: `get_tree().change_scene_to_file.call_deferred(...)`. *(ExitPort → Sandbox; `basic_level._on_exit_port_entered`)*
- Do not permanently set `Camera2D.ignore_rotation = false` in fixed camera mode — the viewport will rotate with any leftover `global_rotation`. `FixedCameraComponent` temporarily sets it `false` only while a mode-switch rotation transition is in progress, then reverts to `true` once settled. *(see docs/claude-camera.md)*
- Do not make `_camera_p1` (or any camera with a world-space position offset) a child of a rotating node. Setting `global_position` stores a local offset that the parent's rotation will silently shift every physics frame until `_process` corrects it, causing jitter. Keep cameras as direct children of their subviewport and sync position manually. *(see docs/claude-camera.md)*
- Do not create `HSlider` nodes without setting `scrollable = false` — mouse scroll over a slider changes its value while the player is scrolling through settings, which is never intended.
- Do not add a `WorldEnvironment` node anywhere — the glow environment comes from the `default_environment` project setting (root viewport only). *(see docs/claude-rendering.md)*
- **Do not set `use_hdr_2d = true` on a SubViewport.** It pulls the full Forward+ 3D post pipeline into the subviewport (~100 ms/frame → ~1 fps). In-game bloom comes from `screen_glow.gdshader`, not HDR 2D. *(see docs/claude-rendering.md)*
- Do not inject runtime `ParticleProcessMaterial` or leave `GPUParticles2D.texture` unset (invisible particles); do not share a per-instance-animated `ShaderMaterial` between scene instances without `resource_local_to_scene = true`.
- When you need different `set_shader_parameter()` values per scene instance at runtime (e.g. bullet color), call `.duplicate()` on the `ShaderMaterial` in `_ready()` and reassign it before setting parameters — otherwise all live instances that share the same sub_resource change simultaneously.
- Do not apply screen shake to `Camera2D.global_position` or rotation — `offset` only. Position fights the per-frame sync in `FixedCameraComponent` / `RelativeCameraComponent`; rotation fights `_display_cam_angle` writes in `RelativeCameraComponent`.
- Do not restore `Engine.time_scale` with a normal timer after hit-stop — the timer must be created with `ignore_time_scale = true` or it is slowed by its own effect.
- Do not mutate `entity.max_health` after `add_child()` and expect `HealthComponent` to reflect the change — `HealthComponent._ready()` already cached `entity.max_health` into `hc.max_health`/`hc.current_health`. Always re-sync the component explicitly: `hc.max_health = ent.max_health; hc.current_health = ent.max_health`. *(enemy stat scaling — `EnemySpawnerComponent._spawn_enemy()`)*
- Do not write `RenderingServer.global_shader_parameter_set` for the `mus_*` globals from anywhere except `MusicManager._process`. *(see docs/claude-music.md)*
- Do not parent one-shot FX to a dying entity — `FXManagerComponent` is the sole spawner and captures the entity's position/neon color synchronously inside the `entity_died` handler. *(see docs/claude-rendering.md)*
- Call `MusicManager.start()` / `MusicManager.stop()` from the level, never from `_ready()`; always call `MusicManager.stop()` before any scene transition that leaves the level. *(see docs/claude-music.md, docs/claude-ui.md)*
- Do not divide onset deltas by `delta` in beat detection — it makes `onset_threshold` framerate-dependent and untunable. *(see docs/claude-music.md)*
- Walls must render **batched** (one `ArrayMesh` via `draw_mesh()`, outline via two `draw_multiline()` calls) — per-primitive `draw_rect`/`draw_line` over the 400×400 arena floods the render thread and tanks fps. *(see docs/claude-music.md)*
- SVG ship trim lines must be white (`#FFFFFF`) so `neon_color` tints them at runtime; the hull fill stays near-black (`#0D0D0F`). *(see docs/claude-ships.md)*
- Use `1.0 - exp(-smoothing * delta)` for camera angle lerps — never `clamp(smoothing * delta, 0, 1)` (snaps at low fps). `Camera2D.ignore_rotation` defaults `true`, so `global_rotation` has no effect until it is set false. *(see docs/claude-camera.md)*
- Never add `class_name` to `MusicManager`, `AdvancedConfig`, `RunState`, or `MetaProgression` — the autoload name is the global identifier; a `class_name` causes a conflict.
- Run-scoped gameplay state lives in `RunState` (wiped each run); persistent unlocks live in `MetaProgression` (saved to `user://`). Never put either in `GameConfig`. *(see docs/claude-roguelike.md)*
- Bank shared run currency in a single global listener — `RunState` subscribes to `EventBus.xp_collected` — never per-entity in `XPComponent`. The pickup signal is entity-less, so per-entity banking silently double-counts the shared wallet in co-op. *(see docs/claude-roguelike.md)*
- In `LevelObjectiveComponent.spawn_boss_now()`, set `_boss_mode = true` and stop the spawner **before** killing existing enemies — enemy deaths call `_on_entity_died`, which could satisfy the kill-quota path and call `_complete()` prematurely if `_boss_mode` isn't set first. *(see docs/claude-roguelike.md)*
- Do not put `_emit_impact()` + `queue_free()` outside the `if area is HurtboxComponent:` block in `Bullet._on_area_entered` — bullets are `Area2D` on layer 1 and `collision_mask = 3` monitors that layer, so burst-fire (radial/spread) spawns several bullets at the same point and they all detect each other. The handler must early-return for non-HurtboxComponent areas; impact and free happen only after valid damage is dealt.
- `ShootComponent.muzzle_offset` applies to the bullet's actual spawn position (`entity.global_position + direction * muzzle_offset`), not just the FX event. Set a larger value on entities with large collision shapes — Boss uses `muzzle_offset = 50.0` to clear its radius-42 collider.
