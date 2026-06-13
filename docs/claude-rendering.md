# Rendering — Bloom, Glow & Impact/Death FX

> Extension of the root `CLAUDE.md`. Read this when touching shaders, bloom/glow, particles, screen-space effects, or perf in the render path. The master gotcha list lives in `CLAUDE.md`.

## Bloom & Glow

The neon look uses **two different bloom paths** — a cheap screen-space glow in gameplay, and the HDR environment glow for menus only.

### In-game glow (gameplay SubViewports) — `screen_glow.gdshader`
- The gameplay SubViewports render in **plain LDR** (`use_hdr_2d` is OFF). **Never enable `use_hdr_2d` on a SubViewport** — HDR 2D on a SubViewport drags the whole Forward+ 3D post pipeline into each subviewport and costs ~100 ms/frame (drops the game to ~1 fps). This was measured and is the single most important perf rule in the project.
- Bloom is instead reproduced by `Components/Shaders/screen_glow.gdshader`: a full-rect `ColorRect` on a `GlowLayer` (`CanvasLayer`, layer 5) in each SubViewport, `blend_add`, sampling `hint_screen_texture` with `filter_linear_mipmap`. It bright-passes the frame (`threshold`) and adds back a few mip LOD taps (pre-blurred by the GPU) → a soft multi-scale halo for ~4 texture fetches (free at 144 fps). Tunables: `threshold`, `strength` (set on the `SM_glow` material in `basic_level.tscn`).
- Because gameplay is LDR, neon colors clamp at 1.0 — there is no >1.0 "overbright" headroom in the world. Drive brightness through saturated colors + the `screen_glow` threshold, not values above 1.0.

### Menu / HUD glow (root viewport) — HDR environment
- `project.godot` sets `rendering/viewport/hdr_2d=true` for the **root viewport only** and `environment/defaults/default_environment="res://Resources/neon_environment.tres"`. The root viewport is cheap to glow (one application, like any normal scene), so menu titles and overbright HUD text (`font_color` > 1.0) bloom via the real environment glow.
- `Resources/neon_environment.tres` is an `Environment` with `glow_enabled`, additive blend, tonemap Linear, applied via the project default — **never add a `WorldEnvironment` node** (all viewports share the root `World3D`; a second environment would conflict).
- Overbright (`font_color` 1.0–3.0) only blooms in the **root viewport** (menus, HUD drawn at root). It does nothing inside the LDR gameplay SubViewports.

### Diagnosing perf (hard-won)
- The project can be driven headlessly for measurement: `Godot --path . res://Levels/LevelPrototype/basic_level.tscn --windowed --always-on-top --resolution 1280x720 --print-fps --quit-after 600`. Headless (`--headless`) runs all game logic with **zero rendering** — if headless is fast but windowed is slow, the cost is in the render path, not CPU/pathfinding.
- The SubViewports have **fixed 960-px offsets** in `basic_level.tscn`, so `--resolution` does not change their internal render size — window resolution is not a valid way to test fill-rate here.

> The `mus_*` shader globals (`mus_bass`/`mus_mid`/`mus_treble`/`mus_beat`) are documented in `docs/claude-music.md` — `MusicManager` is their only writer.

---

## Impact & Death FX

`FXManagerComponent` (`Components/Scripts/fx_manager_component.gd`, level-scope `Node2D` child of SubViewportP1) is the only spawner of one-shot effects. It subscribes to EventBus and spawns `Effects/*.tscn` scenes as its own children at captured world positions — **never parent FX to a dying entity**. Entity position/neon color are read synchronously inside the `entity_died` handler (the entity's `queue_free()` only takes effect after signal emission).

- `entity_died` (enemy only) → `EnemyDeathFX` (shockwave ring + particle burst in the enemy's neon color) + optional hit-stop (`Engine.time_scale` dip; restore timer **must** use `create_timer(d, true, false, true)` — `ignore_time_scale` — and is skipped while paused, guarded by a re-entrancy counter).
- `bullet_impacted(source, world_position, direction, color)` → `BulletImpactFX` sparks (emitted by `bullet.gd` before `queue_free()`; color is `entity.bullet_color`, applied to the bullet via `ShootComponent` after spawning).
- `entity_shot(entity, world_position, direction)` → `MuzzleFlashFX` (emitted by `ShootComponent.shoot()`; players only unless `enemy_muzzle_flash` is on).
- `xp_orb_collected` → gold pickup sparkle.

The manager **prewarms** each effect once at level start (low-alpha play at the player position) so particle/shader pipelines compile before the first real kill.

Particle rules (hard-won): `ParticleProcessMaterial` must be a `[sub_resource]` in the `.tscn` (runtime injection is silently ignored); `GPUParticles2D.texture` must be set or particles are invisible (`GradientTexture2D` sub-resources avoid image assets); `particle_flag_disable_z = true` and `gravity = Vector3(0,0,0)` for 2D; per-instance animated `ShaderMaterial`s (e.g. the shockwave ring `progress`) need `resource_local_to_scene = true` or simultaneous instances fight over uniforms.

### Hit feedback

- `HitFlashComponent` (on Enemy, Player, Player2) listens to `entity_damaged`, drives the `flash_amount` uniform (via `NeonShaderComponent.set_flash()`) plus a scale punch on the visual. `SpawnFXComponent` sets `hit_flash_component.scale_locked` while its spawn tween owns the scale — only one system may write the visual's scale at a time.
- `SpawnFXComponent` (Enemy): materialize-from-light — ring implosion (shockwave shader driven 1→0), visual scale 0→1 `TRANS_BACK`, glow flare.
- `ScreenShakeController` (runtime `.new()` in `basic_level.gd`, like `LevelVisualsController`): trauma-based noise shake applied to **`Camera2D.offset` only** — never `global_position` (fights the per-frame camera sync) and never rotation (fights `_display_cam_angle` in relative mode).
- Damage vignette: the HUD low-HP warning rects use `damage_vignette.gdshader` (`intensity` = persistent low-HP severity + transient spike on `entity_damaged`), gated by `hud_show_low_hp_warning`.
