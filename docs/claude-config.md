# Advanced Settings — AdvancedConfig runtime overrides

> Extension of the root `CLAUDE.md`. Read this when working on the Advanced Settings screen, `AdvancedConfig`, or adding a runtime-tunable property. The master gotcha list lives in `CLAUDE.md`.

The Advanced Settings screen (`Levels/Settings/AdvancedSettings.tscn` + `advanced_settings.gd`) exposes every value-type `@export` variable from all components and entities. It is accessed from the main-menu Settings scene and applies runtime-only overrides (reset on game close).

## AdvancedConfig autoload (`Autoloads/advanced_config.gd`)

- `PROPERTY_DEFS: Array[Dictionary]` — static table of all tunable properties. Each entry has: `"group"`, `"class"` (GDScript class name), `"name"`, `"type"` (TYPE_FLOAT / TYPE_INT / TYPE_BOOL / TYPE_COLOR), `"default"`, and optionally `"min"`, `"max"`, `"step"`.
- `_overrides: Dictionary` — `{ class_name: { prop_name: value } }`. Populated by the UI; read by the node_added hook.
- `_base_values: Dictionary` — `{ class_name: { prop_name: value } }`. Populated at autoload `_ready()` by `_preload_scene_defaults()`, which instantiates each scene in `_SEED_SCENES` in memory (no `_ready()` runs — only saved `.tscn` property values are read), scans the tree recursively, then frees the instance. Also refreshed from live nodes in `_on_node_added` before overrides are applied. Entity scenes are listed after component template scenes in `_SEED_SCENES` so per-instance values overwrite template values.
- `set_override(cls, prop, value)` — stores an override and, for `MusicManager` class entries, applies it immediately to the live singleton.
- `get_override(cls, prop)` — returns, in priority order: user override → actual `.tscn` inspector value (from `_base_values`) → hardcoded default from `PROPERTY_DEFS`.
- `_on_node_added(node)` — fired by `SceneTree.node_added` before the node's `_ready()`. Calls `_capture_node_props` to refresh `_base_values` from the live node's pre-override property values, then applies `_overrides[class_name]` via `node.set(prop, value)`. Special cases: `Player2` nodes also receive all `Player` overrides (movement + combat symmetry); `Enemy` nodes receive only the four combat props from `Player` overrides (`fire_rate`, `bullet_damage`, `bullet_speed`, `max_health`). `bullet_color` is intentionally **not** in `_COMBAT_PROPS` — Player and Enemy bullet colors are independently tunable.

`AdvancedConfig` is a no-`class_name` autoload — never add `class_name AdvancedConfig` (same autoload-name conflict reason as `MusicManager`). It connects to `SceneTree.node_added` in `_ready()` and applies stored overrides to each node before its own `_ready()` runs, so cached values see the correct overridden values.

## Settings navigation flow

```
MainMenu → Settings.tscn (HUD toggles, music toggles, camera toggles/sliders + "ADVANCED SETTINGS" button)
                          → AdvancedSettings.tscn (grouped property list + search bar)
```

Both scenes use `get_tree().change_scene_to_file()` for navigation (no overlay/stack).

## Adding a new tunable property

1. Add an entry to `PROPERTY_DEFS` in `advanced_config.gd` with the correct `"class"` (exact GDScript `class_name` of the owning node), `"group"`, `"name"`, `"type"`, and `"default"`. The `"default"` is a last-resort fallback only; `_base_values` (populated from `_SEED_SCENES` at startup) takes precedence. If the new property's class is not already covered by `_SEED_SCENES`, add its scene path there too.
2. No other changes needed — the UI and override hook read from `PROPERTY_DEFS` automatically.
3. If the property belongs to a class that needs special propagation (e.g. applying to both Player and Player2), add the case to `_on_node_added`.

**Daemons (P7).** Daemon behaviors (`Components/Scripts/Daemons/daemon_*.gd`) are `Node`s with a `class_name` and `@export` tunables, so they integrate here like any component: add a `PROPERTY_DEFS` row per knob, group `"Daemon — <name>"`, with `"default"` **mirroring the `@export` default** (they are not in `_SEED_SCENES`, so the `PROPERTY_DEFS` default is the fallback). The host `add_child()`s each Daemon before reading its values, so `node_added` overrides land in time. The Debug Menu's `DAEMON TUNING` section also edits installed Daemons live and writes through `AdvancedConfig.set_override`.

## Property groups

| Group | Class(es) affected |
|---|---|
| Player Movement | `Player`, `Player2` |
| Player Input | `PlayerInputComponent` |
| Combat | `Player`, `Player2`, `Enemy` (combat props only); `bullet_color` separate per class — not propagated |
| Enemy Spawning | `EnemySpawnerComponent` |
| Level Generation | `ProcGenLevelComponent` |
| Controller Input | `ControllerInputComponent` |
| XP & Progression | `XPDropComponent` |
| Experience Orbs | `ExperienceOrb` |
| Neon Visuals | `NeonShaderComponent` |
| Music Reactivity | `MusicVisualsComponent` |
| Thruster FX | `ThrusterComponent` |
| Thruster Sockets | `ThrusterSocket` (all sockets uniformly) |
| Background | `LevelVisualsController` (background shader tunables + wall edge overbright) |
| Spawn FX | `SpawnFXComponent` |
| Hit Flash | `HitFlashComponent` |
| Screen Shake | `ScreenShakeController` |
| Impact FX | `FXManagerComponent` (FX toggles + hit-stop) |
| Audio Analysis | `MusicManager` (applied immediately, not via node_added) |
| Sector Objective | `LevelObjectiveComponent` (kill quota + exit-port placement + on-complete flags) |
| Exit Port | `ExitPort` (beacon visuals + spawn animation) |
