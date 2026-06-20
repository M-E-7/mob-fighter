# Project TODO & Backlog

> Extension of the root `CLAUDE.md`. Central list of pending work, roadmap items, and ideas. Not authoritative for *how* a subsystem works — that lives in the matching `docs/claude-*.md`. Keep items here; check them off as they land.

**Format:** each task is a checkbox with a priority tag and optional nested subtasks.

```markdown
- [ ] **Task title** `[high]`
  - [ ] subtask
  - [ ] subtask
```

Priority tags: `[high]` / `[med]` / `[low]`. Completed items use `- [x]`.

---

## Gameplay

- [ ] **More enemy types beyond `BasicEnemy`** `[high]`
  - [ ] Ranged shooter (keeps distance, fires bursts)
  - [ ] Fast swarmer (low HP, high speed, attacks in groups)
  - [ ] Tank / heavy (high HP, slow, knockback resistant)
  - [ ] Splitter (spawns smaller enemies on death)
- [ ] **Wave / difficulty scaling** `[high]`
  - [ ] Ramp spawn count / HP / speed over time (`EnemySpawnerComponent` is flat interval + cap today)
  - [ ] Define wave breakpoints or a continuous difficulty curve
- [ ] **Boss encounters** `[med]`
  - [ ] Boss entity + multi-phase behavior
  - [ ] Boss intro / health bar UI hook
- [ ] **Power-up variety beyond flat % stats** `[med]`
  - [ ] Multishot, piercing, spread, lifesteal (extend `PowerUpData` / `power_up_registry.gd`)
  - [ ] Non-stat effect support in the apply path
- [ ] **Secondary fire / weapon variety** `[low]`

## UI / HUD

- [ ] **Wave + survival-time + kill counter on HUD** `[high]`
- [ ] **Off-screen enemy indicators / minimap** `[med]`
- [ ] **Acquired power-up / build display during run** `[med]`
- [ ] **Controller / keybind remapping screen** `[low]`
- [ ] **Co-op join / ready flow** `[low]`

## Visuals / FX

- [ ] **Per-enemy-type death & impact FX variety** `[med]`
- [ ] **Low-health / level-up screen-space effects** `[low]`
- [ ] **Bullet trail variety per weapon** `[low]`

## Architecture / Quality of Life

- [ ] **Settings persistence** `[high]`
  - [ ] Persist `GameConfig` HUD/camera toggles across sessions (no `user://`/`ConfigFile` save exists today)
- [ ] **Data-drive enemies via Resources** `[med]`
  - [ ] Mirror the `PowerUpData` pattern for enemy stats/behavior
- [ ] **Centralized balance / tuning resource** `[low]`

## Level Design Improvements

- [ ] **Multiple arena layouts / biomes** `[med]`
- [ ] **In-arena obstacles / cover** `[med]`
- [ ] **Environmental hazards** `[low]`
- [ ] **Arena size scaling with difficulty** `[low]`

## Performance Optimization

- [ ] **Bullet / enemy object pooling** `[high]`
- [ ] **Audit per-frame `get_nodes_in_group("enemy")` calls** `[med]`
  - [ ] Spawner cap check and any AI that re-queries the group each frame
- [ ] **Profile & reduce per-frame allocations** `[low]`
