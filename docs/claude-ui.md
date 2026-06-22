# UI Theme & Pause System

> Extension of the root `CLAUDE.md`. Read this when working on menus, the HUD theme, or the pause system. The master gotcha list lives in `CLAUDE.md`.

## UI Theme

All menus share `UI/Themes/neon_theme.tres` (Button/PanelContainer/ProgressBar styleboxes with glow shadows, `SystemFont` Bahnschrift→Segoe UI, light label color). Applied on the root `Control` of MainMenu/Settings/AdvancedSettings and on the `Dim` rect of CanvasLayer UIs (Pause/GameOver/LevelUp); `hud.gd` preloads it onto its code-built panels. Title labels use **overbright `font_color` overrides** (e.g. `Color(0.4, 2, 1.8)`) — root-viewport HDR blooms them. Per-scene stylebox overrides (HUD accents, main-menu buttons) intentionally take precedence over the theme. Damage numbers (`floating_text.gd`) draw an outline pass plus a 1.6× overbright fill.

## Pause System

ESC during gameplay is handled by `basic_level.gd` via `_unhandled_input`. It instantiates `PauseMenuUI` (`UI/PauseMenuUI.tscn`) lazily on first press, sets `get_tree().paused = true`, and shows the overlay. `PauseMenuUI` uses `PROCESS_MODE_ALWAYS` so its buttons and `_input` work while the tree is paused.

Key rules:
- `PauseMenuUI._input` guards `if not visible: return` — a hidden `PROCESS_MODE_ALWAYS` node still receives input, so without the guard it silently consumes ESC even when off-screen.
- Always call `get_tree().paused = false` **before** `change_scene_to_file()` — a paused tree blocks scene loading.
- Always call `MusicManager.stop()` before any scene transition that leaves the level (both game-over and pause-to-menu paths).
- `basic_level._game_over_shown` blocks ESC after all players die so the pause menu can't open over the game-over screen. (The in-run `LevelUpUI` was removed in P1; the scene/script are retained for the future Sandbox shop but are no longer instantiated during a sector.)

## Debug Menu (P11)

**Alt** toggles `DebugMenuUI` (`UI/DebugMenuUI.tscn` + `UI/debug_menu_ui.gd`). Same pattern as `PauseMenuUI`: CanvasLayer `layer = 20` (above pause's 15), `PROCESS_MODE_ALWAYS`, `_input` guards `if not visible: return`. The level's `_unhandled_input` detects Alt (it only fires when unpaused), and the menu's own `_input` handles close (fires while paused because it's ALWAYS). Force win/game-over emit signals to the level which unpauses first — `change_scene_to_file()` is forbidden while paused.
