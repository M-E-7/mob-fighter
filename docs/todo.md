# Project TODO & Backlog

> Extension of the root `CLAUDE.md`. Central list of pending work, roadmap items, and ideas. Not authoritative for *how* a subsystem works — that lives in the matching `docs/claude-*.md`. Keep items here; check them off as they land.
>
> **Headline initiative: the roguelike overhaul** (see `docs/claude-roguelike.md` for the full design/contract). The *Roguelike Core Loop* section below is the phased build order (P1–P10); the themed sections feed those phases.

**Format:** each task is a checkbox with a priority tag and optional nested subtasks.

```markdown
- [ ] **Task title** `[high]`
  - [ ] subtask
  - [ ] subtask
```

Priority tags: `[high]` / `[med]` / `[low]`. Completed items use `- [x]`.

---

## Roguelike Core Loop `[high]`

> Convert the survival prototype into a run-based roguelike. Design & contract: `docs/claude-roguelike.md`. Phases are ordered; each is independently playable/verifiable. Working content names (Bits, Daemons, Sandbox, Sectors…) are placeholders — easy to swap.

- [x] **P1 — RunState + currency refactor** `[high]`
  - [x] Add `RunState` autoload (no `class_name`): `current_level`, `currency`, `owned_upgrades`, `owned_modifiers`, `reset()`, `apply_to(entity)`
  - [x] Repurpose `XPComponent`: bank orbs into `RunState.currency`; strip the auto-level-up branch + `current_level`
  - [x] **Remove the in-run level-up** — retire the `player_leveled_up` → `LevelUpUI` trigger (keep the card layout for the shop)
  - [x] `EventBus.currency_changed(total)`; HUD Bits readout
- [x] **P2 — Objective + exit portal** `[high]`
  - [x] Objective driver (`LevelObjectiveComponent`) keyed off `current_level` (kill-quota shipped; survive-timer/boss deferred); tracks group-`enemy` `entity_died`
  - [x] `ExitPort` Area2D entity; spawn on objective complete; overlap → `MusicManager.stop()` → Sandbox (stub). Spawner-stop/enemy-clear are optional `@export` flags (default: keep spawning, per the agreed sector feel)
  - [x] HUD objective-progress readout (`hud_show_objective` toggle)
- [x] **P3 — Sandbox (shop)** `[high]`
  - [x] `Levels/Sandbox/` scene — 3-card random stock, Reroll, Repair (HP carryover via `RunState.health_fraction`), Continue/Abandon; `neon_theme.tres` + P2 keyboard cursor
  - [x] `PowerUpData.cost: int`; re-themed names (Defrag/Overclock/Heap Smash/Firewall/Packet Burst); escalating cost formula `cost * (1 + 0.5 * stacks_owned)` in `RunState.upgrade_cost()`
  - [x] Buy → `RunState.buy_upgrade()` → deduct `currency` → `owned_upgrades`; `RunState.apply_to()` + HP restore wired in `basic_level._ready()`; Continue → `current_level += 1` → reload sector
- [x] **P4 — Run flow / win + lose** `[high]`
  - [x] MainMenu Start → `RunState.reset()`; multi-sector loop; `current_level += 1` in Sandbox
  - [x] Win screen (`WinUI`) after the final sector's ExitPort; any death = run over → Game Over + `RunState.reset()` on PLAY AGAIN
  - [x] `RunState.run_kills`/`run_time` cumulative stats; both end screens show whole-run totals
  - [ ] Win screen should pause the game (same as Game Over) `[low]`
- [x] **P5 — Difficulty scaling** `[high]` *(was "Wave / difficulty scaling")*
  - [x] Scale `EnemySpawnerComponent` (`spawn_interval`, `max_enemies`) by `current_level`/Threat Level
  - [x] Scale enemy stats (HP, damage, speed) per sector via multipliers applied in `_spawn_enemy()`
  - [x] Vary `ProcGenLevelComponent` (size, `obstacle_density`) per sector; seed already randomized each run
  - [x] Scale kill quota (`LevelObjectiveComponent`) per sector
  - [x] Difficulty curve: `RunState.sector_t()` (linear 0→1) + `threat_factor()` (P9 stub, default ×1.0)
  - [x] Debug sector-jump: "Reload as Sector N" in DebugMenuUI (enables P5 verification without playing through)
- [x] **P6 — Bosses** `[high]` *(was "Boss encounters", bumped)*
  - [x] Boss entity + multi-phase behavior; spawned by the objective driver
  - [x] Boss intro + on-screen HP-bar UI hook
  - [x] Miniboss ≈ sector 5 (Trojan/Rootkit); final boss = sector 10 (**rogue AI / system core**)
  - [x] Fix boss burst bullets destroying each other — `Bullet._on_area_entered` now early-returns for non-HurtboxComponent areas; `ShootComponent` applies `muzzle_offset` to spawn position; Boss ShootComponent `muzzle_offset = 50.0`
- [ ] **P7 — Daemons (modifier system)** `[high]` *(was "Power-up variety beyond flat % stats")*
  - [ ] `DaemonHost` component + hook points (`on_shoot`/`on_hit`/`on_kill`/`on_damage_taken`/`on_process`); reuse existing `EventBus` signals where possible
  - [ ] `ModifierData` resource + `ModifierRegistry` autoload (mirrors `PowerUpRegistry`)
  - [ ] First Daemon set: Overclock, Heuristic Scanner, Quarantine, Fork Bomb, Firewall, Garbage Collector
  - [ ] Effect candidates to build as Daemons/Upgrades: multishot, piercing, spread, lifesteal, ricochet/bounce, split
  - [ ] Sell Daemons in the Sandbox alongside generic Upgrades
- [ ] **P8 — Save layer (`user://`)** `[high]` *(also satisfies the old "Settings persistence")*
  - [ ] `ConfigFile` (or save Resource) util/autoload; save on change, load at startup
  - [ ] Persist `GameConfig` HUD/camera/music toggles across sessions
- [ ] **P9 — Meta-progression** `[med]`
  - [ ] `MetaProgression` autoload (no `class_name`): `unlocked_ships/daemons/skins`, `cleared_threat_level`, `achieved`
  - [ ] `record_run_end(won)` — evaluate milestones on every run end (win or loss), unlock, save
  - [ ] Milestone → unlock tables (ships / daemons / skins); **Threat-Level** ladder
  - [ ] MainMenu ship / skin / Threat-Level select (the "Mainframe")
  - [ ] Unlocks are **variety, not power** — keep core-loop balance intact
- [ ] **P10 — Content & variety** `[med]`
  - [ ] Draws from the themed sections below (malware types, sector biomes, random Bit events, expanded catalogs)
- [x] **P11 — In-game debug menu** `[med]`
  - [x] Alt toggles overlay (pauses game); `DebugMenuUI` mirrors `PauseMenuUI` pattern (CanvasLayer layer 20, `PROCESS_MODE_ALWAYS`, `_input` visibility guard)
  - [x] Edit Bits, player health (per-player SpinBox), objective requirement + progress
  - [x] Quick-grant Bits (+100 / +1000 buttons)
  - [x] God mode toggle (invincible flag on `HealthComponent`, resets each sector)
  - [x] Full heal (per player)
  - [x] Complete Objective Now (spawns ExitPort)
  - [x] Kill All Enemies, Force Win, Force Game Over
  - [x] Read-only info panel: FPS, enemy count, sector, P1 position
  - [x] Jump `current_level` to any sector ("Reload as Sector N" — landed in P5)
  - [x] Spawn enemies/bosses on demand

---

## Gameplay

- [ ] **Malware enemy archetypes (beyond `BasicEnemy`)** `[high]` *(feeds P10)*
  - [ ] **Spyware** — ranged shooter (keeps distance, fires bursts)
  - [ ] **Worm / Bot** — fast swarmer (low HP, high speed, attacks in groups)
  - [ ] **Rootkit / Ransomware** — tank / heavy (high HP, slow, knockback-resistant)
  - [ ] **Virus** — splitter (spawns smaller malware on death)
- [ ] **Random Bit events** `[med]` *(feeds P10; orb pickups beyond enemy drops)*
  - [ ] Honeypot caches (risk/reward), fleeing data-drone payout, defend-the-beacon decrypt, elite/golden malware, risk zones
- [ ] **Secondary fire / weapon variety** `[low]`

## UI / HUD

- [x] **Sector HUD: objective progress + Bits balance + sector number** `[high]` *(P2: objective readout + sector number + Bits all on the HUD)*
- [x] **Boss intro + HP bar** `[high]` *(P6)*
- [ ] **Off-screen enemy indicators / minimap** `[med]`
- [x] **Off-screen ExitPort marker + distance indicator** `[high]` *(P2 UX follow-up)*
  - [x] Edge-of-screen arrow/marker pointing toward the portal while it is off-screen
  - [x] Distance-to-port readout on/near the marker
  - [x] Hide once the port is on-screen; consider sharing the mechanic with the off-screen enemy indicators above
- [ ] **Acquired Upgrades / Daemons (build) display during run** `[med]`
- [ ] **Controller / keybind remapping screen** `[low]`
- [ ] **Co-op join / ready flow** `[low]`

## Visuals / FX

- [ ] **Per-malware-type death & impact FX variety** `[med]`
- [ ] **Low-Integrity / boss / portal screen-space effects** `[low]`
- [ ] **Bullet trail variety per weapon / Daemon** `[low]`

## Architecture / Quality of Life

- [ ] **Save-system foundation (`user://`)** `[high]` *(now P8 — powers meta-progression AND settings persistence)*
  - [ ] Persist `GameConfig` HUD/camera toggles across sessions (no `user://`/`ConfigFile` save exists today)
- [ ] **Data-drive enemies via Resources** `[med]`
  - [ ] Mirror the `PowerUpData` pattern for malware stats/behavior
- [ ] **Centralized balance / tuning resource** `[low]`

## Level Design Improvements

- [ ] **Multiple sector layouts / biomes** `[high]` *(feeds P5/P10; filesystem → network → memory → registry → kernel)*
- [ ] **In-arena obstacles / cover** `[med]`
- [ ] **Environmental hazards** `[low]`
- [ ] **Sector size scaling with difficulty** `[low]` *(feeds P5)*

## Performance Optimization

- [ ] **Bullet / enemy object pooling** `[high]`
- [ ] **Audit per-frame `get_nodes_in_group("enemy")` calls** `[med]`
  - [ ] Spawner cap check and any AI that re-queries the group each frame
- [ ] **Profile & reduce per-frame allocations** `[low]`
