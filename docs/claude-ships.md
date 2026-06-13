# Player Ship Models — visuals, neon shader & thrusters

> Extension of the root `CLAUDE.md`. Read this when working on the player ship visuals, the neon shader, thrusters/sockets, or adding a new ship. The master gotcha list lives in `CLAUDE.md`. Music analysis that drives these is in `docs/claude-music.md`.

Each player ship is a `ShipModel` scene (`Entities/Player/Ships/<ShipName>.tscn`) that owns the ship's visual and thruster layout. The `Player` entity instances one ship scene as a child named `PlayerShip`.

## ShipModel (`Entities/Player/Ships/ship_model.gd`)
- `@export var neon_component: NeonShaderComponent` — wired to the sibling `NeonShaderComponent` inside the ship scene
- `@export var thruster_component: ThrusterComponent` — wired to the sibling `ThrusterComponent`
- `@export var collision_shape: Shape2D` — per-ship hitbox; `Player._ready()` applies it to the entity's `CollisionShape2D`
- `setup(entity: LivingEntity)` — called by `Player._ready()` to inject the entity reference into sub-components after the scene tree is ready

## NeonShaderComponent API
`set_visual_params(glow: float, pulse_spd: float, feather: float, pulse_amt: float)` updates shader uniforms without allocating a Dictionary. Base values (`neon_color`, `pulse_speed`, etc.) are cached from the component's exports in `_ready()` by `MusicVisualsComponent`. `set_flash(amount)` drives the `flash_amount` hit-flash uniform (both neon shaders have it); `get_visual()` returns the resolved visual `CanvasItem` (used by `HitFlashComponent` and `SpawnFXComponent` for scale animation).

`NeonShaderComponent._ready()` auto-selects its shader based on the visual node type:
- `Sprite2D` → `sprite_neon_shader.gdshader`: luminance-based — bright pixels become `neon_color × glow_intensity × pulse`, dark pixels stay dark. **SVG trim lines must be white (`#FFFFFF`)** so `neon_color` tints them at runtime; the hull fill should be near-black (`#0D0D0F`).
- `MeshInstance2D` → `neon_shader.gdshader`: original circle SDF shader (used by enemies).

`NeonShaderComponent` has two ways to locate the visual node:
1. **`visual_node` export** (`CanvasItem`) — set this explicitly when the component lives inside a ship scene (i.e. not a direct child of the entity). `_ready()` uses it directly, no entity lookup needed. Set to `NodePath("../SpriteDisplay")` in ship scenes.
2. **Auto-detect via `entity`** — fallback when `visual_node` is null. Searches the entity's full subtree by name (`CircleDisplay`, `SpriteDisplay`), then any direct `Sprite2D`/`MeshInstance2D` child.

Player's `SpriteDisplay` (Sprite2D, `Entities/Player/player_ship.svg`) lives inside the ship model scene. Enemy entities use `CircleDisplay` (MeshInstance2D) as a direct entity child and rely on auto-detect.

## ThrusterComponent (player-only)
`Components/Scripts/thruster_component.gd` — extends `Node2D`. Manages five `ThrusterSocket` children (each a `Node2D` with a `MeshInstance2D` beam quad). Sockets are defined in `Entities/Player/Ships/PlayerShip.tscn`:

| Socket | Position (local) | Rotation | Fires when |
|---|---|---|---|
| `MainSocket` | `(0, 7.4)` | 0° | moving forward |
| `LeftRetroSocket` | `(-6.1, 2.4)` | 180° | moving backward |
| `RightRetroSocket` | `(6.1, 2.4)` | 180° | moving backward |
| `LeftSocket` | `(-10.1, 5.5)` | 90° | strafing to ship's right |
| `RightSocket` | `(10.1, 5.5)` | −90° | strafing to ship's left |

All groups fire **independently** — no priority chain. Each group fires when its corresponding key is held: W fires main, S fires retro, A fires right-side sockets (reaction thrust left), D fires left-side sockets (reaction thrust right). Space (turbo) always fires the main thruster regardless of W. `brightness` for non-main sockets is `base_brightness + MusicManager.bass * music_bass_add + beat_spike * beat_spike_strength`; main sockets additionally add `turbo_brightness_add` and scale by `turbo_scale_mult` when turbo is active (both exports on `ThrusterComponent`). Each socket's beam is a tapered cone shader (`Components/Shaders/thruster_beam.gdshader`) with additive blending, glow, and shimmer. Socket rotation determines beam direction — the beam always extends along the socket's local +Y axis. `player_ship.svg` has matching nozzle ellipses at each position.

## ThrusterSocket (`Components/Scripts/thruster_socket.gd`)
- Extends `Node2D`. Each socket is a nozzle attachment point placed by hand in the ship scene editor.
- `fire_when: FireWhen` enum (`FORWARD`, `BACKWARD`, `STRAFE_LEFT`, `STRAFE_RIGHT`) — which movement direction activates this socket.
- `beam_length`, `beam_width`, `beam_color`, `shimmer_strength`, `shimmer_speed`, `trail_duration`, `trail_radius`, `transition_time` — all `@export`, tunable per socket in the inspector. Scale animates smoothly via `_current_scale_mult` lerping toward `_target_scale_mult` at the same rate as `transition_time`.
- Has a single `BeamMesh` (`MeshInstance2D`) child. In `_ready()`, the socket creates a `QuadMesh` (`beam_width * 2.0` wide to give the outer halo room) and a `ShaderMaterial` pointing to `thruster_beam.gdshader`, then assigns both to the mesh.
- `set_active(active: bool, brightness: float)` — sets `_target_active` and updates the `brightness` shader param; does **not** toggle visibility directly.
- Appear/disappear uses a `_transition` float (0→1) driven each frame at rate `1 / transition_time`. The `BeamMesh` scale and `position.y` both scale with `_transition` (keeping the nozzle end fixed while the tail grows outward), and `modulate.a` fades simultaneously. The mesh is hidden only when `_transition ≤ 0.001`.

**Beam shader** (`Components/Shaders/thruster_beam.gdshader`) — three additive layers rendered in one pass:
- *Gaussian core* — tight white-hot spine (`exp(-d²/r²)`), bleeds from near-white at the nozzle to `beam_color` toward the tip.
- *Neon body* — main plasma volume (`pow(1-norm, 1.8)`), full `beam_color`.
- *Outer halo* — soft volumetric fringe (`pow(1-norm, 4.0)`) extending to 92 % of the quad half-width; gives the ion-drive glow effect.
- Two-frequency shimmer + slow lateral drift animate the beam organically. `render_mode blend_add` — no dark-box artefacts over the background.
- UV.y = 0 is the **bottom** of the `QuadMesh` in Godot 4, so the shader uses `float v = 1.0 - UV.y` to map v=0 to the nozzle.

**Trail** — `ThrusterSocket` owns a world-space position history and draws it via `_draw()`:
- Each `_process()` frame while `_target_active` is true, the socket's `global_position` is appended to `_trail_pos` / `_trail_time` arrays if the ship has moved ≥ `_SAMPLE_DIST` (3 px) since the last sample. Sampling stops when the key is released, but the existing trail continues to render and fade naturally during the beam's fade-out transition.
- `_draw()` iterates the history, converts each world point to local space with `to_local()`, and draws two concentric additive circles (outer halo + bright core) whose radius and alpha both decay quadratically with age.
- A `CanvasItemMaterial` with `BLEND_MODE_ADD` is set on the socket root in `_ready()` so the `_draw()` circles are additive. The `BeamMesh` child has its own `ShaderMaterial` and is unaffected by the parent's material.
- `_prune_trail()` removes entries older than `trail_duration` every frame; `queue_redraw()` is called only while the trail array is non-empty.

## Adding a new ship
1. Duplicate `Entities/Player/Ships/PlayerShip.tscn` → rename (e.g. `HeavyShip.tscn`)
2. Swap the `SpriteDisplay` texture to the new SVG
3. Move / add / remove `ThrusterSocket` nodes in the editor to match the new nozzle positions; adjust `beam_length` and `beam_width` per socket
4. Set a ship-appropriate `collision_shape` on the root node
5. In `player.tscn`, replace the `PlayerShip` instance with the new scene — no script changes needed

## Cross-scene entity wiring
`NeonShaderComponent` and `ThrusterComponent` are grandchildren of `Player` (inside the ship scene). They cannot reliably use a `NodePath` that crosses the sub-scene boundary during `_ready()`. Instead:
- `NeonShaderComponent` uses `visual_node = NodePath("../SpriteDisplay")` (sibling, within the sub-scene) — entity is not required at startup
- `ThrusterComponent` receives entity via `ShipModel.setup()` from `Player._ready()`, which runs before any `_process()` call
