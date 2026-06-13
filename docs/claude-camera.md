# Camera System

> Extension of the root `CLAUDE.md`. Read this when working on the camera, relative/fixed modes, look-ahead, or screen shake. The master gotcha list lives in `CLAUDE.md`.

Cameras are created at runtime in `basic_level.gd` — there is no camera component. Both `_camera_p1` and `_camera_p2` are direct children of their respective subviewports (`SubViewportP1` / `SubViewportP2`) and are position-synced manually every `_process` frame. `_camera_p1` must **not** be a child of the player — setting `global_position` on a camera that is a child of a rotating node stores a local offset that shifts when the parent rotates, causing one-frame jitter on every physics step.

Two modes controlled by `GameConfig.camera_relative_mode`:

**Fixed mode**: `Camera2D.ignore_rotation = true`. Camera position is set to `_player1.global_position` each frame; view stays axis-aligned regardless of ship heading.

**Relative mode**: Camera rotates to keep the mouse direction pointing toward screen-top, while the ship turns toward it at its normal `turn_speed`. Camera is also offset forward (look-ahead) in the camera's current heading direction.

## Relative mode implementation

- `Input.MOUSE_MODE_CAPTURED` is set on level start — cursor is hidden and locked to the window center, reporting relative deltas instead of absolute position. Mouse is restored to `MOUSE_MODE_VISIBLE` when the pause menu opens or game over triggers; re-captured on resume.
- `basic_level._unhandled_input` accumulates `InputEventMouseMotion.relative.x * GameConfig.mouse_sensitivity` into `_rel_cam_angle` (raw target angle, unbounded). Only the X axis is used — vertical mouse movement has no effect.
- Each `_process` frame, `_display_cam_angle` is smoothed toward `_rel_cam_angle` using the frame-rate-independent formula `lerp_angle(_display_cam_angle, _rel_cam_angle, 1.0 - exp(-camera_smoothing * delta))`. The camera's `global_rotation` is set to `_display_cam_angle`. Do **not** use `clamp(smoothing * delta, 0, 1)` — that formula hits 1.0 at low framerates and causes instant snaps.
- `Camera2D.ignore_rotation = false` is required for the rotation to affect the viewport. Set each frame in relative mode; reverted to `true` in fixed mode.
- `_input_comp_p1.relative_camera_angle` is set to `_rel_cam_angle` (not `_display_cam_angle`) each frame so the ship always aims at the true target, not the smoothed camera position.

## Look-ahead

In relative mode, the camera is offset forward so the player sees more of the arena ahead:

- `_look_ahead_angle` — a second smoothed angle, driven by `1.0 - exp(-camera_look_ahead_smoothing * delta)` (default smoothing 8, much lower than rotation smoothing 30). This decouples the position offset from the rotation: the viewport rotates responsively, but the look-ahead direction drifts smoothly, preventing the arc-translation jitter that would otherwise occur when both rotation and position change simultaneously.
- `fwd = Vector2(sin(_look_ahead_angle), -cos(_look_ahead_angle))` — world-space forward direction for the current look-ahead angle (θ=0 → `(0,-1)` = screen-up = ship heading).
- `_camera_p1.global_position = _player1.global_position + fwd * GameConfig.camera_look_ahead`
- Both `camera_look_ahead` (distance, default 150 px) and `camera_look_ahead_smoothing` are tunable via the Settings scene.

## Key gotchas
- `Camera2D.ignore_rotation` defaults to `true` — setting `camera.global_rotation` has **no visual effect** until this is set to `false`.
- Never make `_camera_p1` a child of the rotating player node. Setting `global_position` on such a camera stores a local offset; any subsequent parent rotation shifts the camera's world position until the next `_process` corrects it, producing physics-rate jitter.
- Do not use `clamp(smoothing * delta, 0, 1)` for camera lerp — use `1.0 - exp(-smoothing * delta)` for frame-rate independence.
- Screen shake is applied to `Camera2D.offset` only — never `global_position` or rotation (see `docs/claude-rendering.md`, Hit feedback).
