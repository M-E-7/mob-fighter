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

- [ ] **P1 — RunState + currency refactor** `[high]`
  - [ ] Add `RunState` autoload (no `class_name`): `current_level`, `currency`, `owned_upgrades`, `owned_modifiers`, `reset()`, `apply_to(entity)`
  - [ ] Repurpose `XPComponent`: bank orbs into `RunState.currency`; strip the auto-level-up branch + `current_level`
  - [ ] **Remove the in-run level-up** — retire the `player_leveled_up` → `LevelUpUI` trigger (keep the card layout for the shop)
  - [ ] `EventBus.currency_changed(total)`; HUD Bits readout
- [ ] **P2 — Objective + exit portal** `[high]`
  - [ ] Objective driver keyed off `current_level` (kill quota / survive timer / boss); track via `entity_died` + frame timer
  - [ ] `ExitPort` Area2D entity; spawn on objective complete; stop spawner; overlap → `MusicManager.stop()` → Sandbox (stub)
  - [ ] HUD objective-progress readout
- [ ] **P3 — Sandbox (shop)** `[high]`
  - [ ] `Levels/Sandbox/` scene reusing the `LevelUpUI` card pattern + `neon_theme.tres`
  - [ ] Extend `PowerUpData` with `cost: int`; generic-upgrade catalog via the `PowerUpRegistry._make()` pattern
  - [ ] Buy → deduct `currency` → `owned_upgrades`; `RunState.apply_to()` on next sector spawn; Continue → next sector
- [ ] **P4 — Run flow / win + lose** `[high]`
  - [ ] MainMenu Start → `RunState.reset()`; multi-sector loop; `current_level += 1` in Sandbox
  - [ ] Win screen after the final boss; any death = run over → Game Over
- [ ] **P5 — Difficulty scaling** `[high]` *(was "Wave / difficulty scaling")*
  - [ ] Scale `EnemySpawnerComponent` (`spawn_interval`, `max_enemies`) by `current_level`/Threat Level (flat today)
  - [ ] Vary `ProcGenLevelComponent` (size, `obstacle_density`, seed) per sector
  - [ ] Define the difficulty curve (breakpoints or continuous)
- [ ] **P6 — Bosses** `[high]` *(was "Boss encounters", bumped)*
  - [ ] Boss entity + multi-phase behavior; spawned by the objective driver
  - [ ] Boss intro + on-screen HP-bar UI hook
  - [ ] Miniboss ≈ sector 5 (Trojan/Rootkit); final boss = sector 10 (**rogue AI / system core**)
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

- [ ] **Sector HUD: objective progress + Bits balance + sector number** `[high]` *(feeds P2; reframe of wave/kill counter)*
- [ ] **Boss intro + HP bar** `[high]` *(feeds P6)*
- [ ] **Off-screen enemy indicators / minimap** `[med]`
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
