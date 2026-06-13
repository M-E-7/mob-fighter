# Music System — analysis & music-reactive visuals

> Extension of the root `CLAUDE.md`. Read this when working on audio analysis, beat detection, music-reactive visuals, the procedural walls, or the level background. The master gotcha list lives in `CLAUDE.md`. Ship-specific visual components (`NeonShaderComponent`, `ThrusterComponent`) are in `docs/claude-ships.md`.

Real-time audio analysis drives the visual systems. All tuneable values are `@export` — adjust in the Godot inspector, never hardcode.

## MusicManager (autoload)
Reads the spectrum analyzer each frame and publishes:
- `bass`, `mid`, `treble` — smoothed 0–1 floats for 20–300 Hz, 300–2000 Hz, 2000–16000 Hz
- `raw_bass`, `raw_mid`, `raw_treble` — unsmoothed samples (use for beat detection, not visuals)
- `onset_energy` — sum of positive per-frame raw band deltas; spikes on any transient
- `beat_cooldown_remaining` — seconds until the next beat can fire

Beat detection uses onset: `onset_energy > onset_threshold AND cooldown <= 0` → emits `EventBus.beat_detected`. Do **not** divide onset deltas by `delta` — that scales values to framerate-dependent magnitudes and makes thresholds untunable.

`MusicManager` is a no-`class_name` autoload — the singleton name IS the global identifier; adding `class_name` causes a conflict. Call `MusicManager.start()` / `MusicManager.stop()` from the level, never from `_ready()`.

## Music shader globals

`MusicManager._process` publishes four global shader uniforms via `RenderingServer.global_shader_parameter_set`: `mus_bass`, `mus_mid`, `mus_treble`, `mus_beat` (beat flash 1→0, decay `beat_flash_decay`). They are declared in `project.godot` `[shader_globals]`. Any shader can react to music with `global uniform float mus_bass;` — no script wiring. MusicManager is the **only** writer, and it zeroes all four when `GameConfig.music_visuals_enabled` is off, so consumers never need their own toggle check.

## Visual drivers
| System | File | Drives |
|---|---|---|
| Entity neon | `Components/Scripts/music_visuals_component.gd` | `NeonShaderComponent` glow, pulse speed, feather, pulse amount |
| Thruster FX | `Components/Scripts/thruster_component.gd` | `ThrusterSocket` children — beam `brightness` modulated by bass + beat spike |
| Level background | `Levels/LevelPrototype/level_visuals_controller.gd` | Camera uniforms + tunables on the `neon_background.gdshader` rects, wall outline `self_modulate` |
| Wall fill | `Components/Shaders/wall_fill.gdshader` | Scanline shimmer via `mus_bass` shader global |
| XP orbs | `Components/Shaders/xp_orb.gdshader` | Halo glow via `mus_bass` shader global |
| Debug HUD | `UI/music_visualizer_hud.gd` | Visualizer bars (Bass/Mid/Treble/Onset), beat indicator, cooldown bar |

## Walls
`ProcGenLevelComponent` contains two **batched** renderers (the 400×400 arena means tens of thousands of wall primitives — per-primitive `draw_rect`/`draw_line` calls flood the render thread and tank fps, so both must batch):
- `WallRenderer` builds **one `ArrayMesh`** (two triangles per merged rect) in `build_mesh()` after generation and draws it with a single `draw_mesh()` call. `wall_fill.gdshader` computes the panel look (scanlines, tile variation) from a `varying vec2 world_pos` captured in `vertex()` — `_draw()` has no usable UVs, so world space is the only stable basis.
- `WallOutlineRenderer` computes outer perimeter edges from the raw grid on generation into one flat `PackedVector2Array`, and draws the whole outline with **two `draw_multiline()` calls** (wide translucent under-pass + crisp line) — one batched primitive each, not one `draw_line` per segment. Color is updated via `self_modulate` every frame — **no `queue_redraw()`**. `LevelVisualsController` multiplies the edge rgb by `wall_edge_overbright` (the white outline reads as bright, picked up by `screen_glow`) before calling `update_wall_visuals(edge_col, glow_a)`.

## Level background
Each SubViewport owns a `BackgroundLayer` (`CanvasLayer`, layer −10) → `NeonBackground` (full-rect `ColorRect` with `neon_background.gdshader`). The shader reconstructs the world position under each pixel from `cam_pos` / `cam_rot` / `cam_zoom` uniforms (pushed every frame by `LevelVisualsController._update_backgrounds()` using `camera.get_screen_center_position()`), then layers a bass-driven base wash, drifting nebula, three parallax starfields, and a world-locked beat-pulsing grid. CanvasLayers attach per-viewport, so each split-screen half tracks its own camera even though P2 shares P1's `world_2d`. The camera uniforms are pushed regardless of the music toggle — only the music reaction is gated (via the zeroed `mus_*` globals).
