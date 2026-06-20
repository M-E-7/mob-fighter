# Roguelike loop — run flow, sectors, Sandbox shop, Daemons & meta-progression

> Extension of the root `CLAUDE.md`. Read this before working on the run loop, currency, the shop, the modifier ("Daemon") system, bosses, or meta-progression. The master gotcha list lives in `CLAUDE.md`; the phased build order lives in `docs/todo.md`.

**Implementation status: P1 DONE; P2–P10 are design.** This file is the agreed contract the roadmap (`docs/todo.md` → *Roguelike Core Loop*, phases P1–P10) builds against. **Built (P1):** the `RunState` autoload, Bits currency banking (`EventBus.currency_changed`), and removal of the in-run level-up — see the **Currency** section for the as-built notes. Everything else (`MetaProgression`, `ExitPort`, the Sandbox, Daemons, bosses) is still the *intended* API; verify a symbol exists before relying on it in code. Working content names (Bits, Daemons…) are placeholders that are easy to swap — the display string is centralized as `RunState.CURRENCY_NAME`.

---

## Theme & narrative

The player is an **antivirus ship** injected into a computer system, descending through its **sectors** to purge **corruptions, viruses, trojans, worms, rootkits, malware, and rogue AI**. The final sector's boss is a malevolent **rogue AI / system core**; beating it wins the run.

The game stays a top-down *ship* shooter — the existing neon "space" aesthetic is reinterpreted as the visual language of *inside the machine*, so no art direction is lost. **All new content must fit the cyber fiction**: enemies are malware archetypes, pickups are data, upgrades are software. When naming anything new, reach for the glossary below first.

---

## Run lifecycle

A **run** is a sequence of sectors played start-to-finish; it ends in a win (final boss cleared) or a loss (all players' Integrity hits 0). `basic_level.tscn` is **reused** for every sector; `RunState.current_level` parameterizes procgen, spawner difficulty, objective, and boss spawning.

```
MainMenu ──(pick ship / skin / Threat Level, Start)──> RunState.reset()
   │
   ▼
Sector n   (basic_level.tscn; RunState.apply_to(player) on each spawn)
   │   collect Bits · fight malware · meet the sector objective
   ▼
ExitPort spawns near the player ──(enter)──> MusicManager.stop()
   │
   ▼
Sandbox (shop scene)   spend Bits on Upgrades + Daemons
   │   Continue → RunState.current_level += 1
   ├── sectors remain ───────────> Sector n+1
   └── final boss was cleared ───> Win screen
                                        │
(any player Integrity → 0) ─────> Game Over
                                        │
        both endings ──> MetaProgression milestone check + save ──> MainMenu
```

The transition out of every sector goes through the **`MusicManager.stop()` before `change_scene_to_file()`** rule (see `CLAUDE.md` gotchas). Unpause before any transition.

---

## Two-tier state model

Keep three storage layers strictly separate — this is the most important architectural rule of the overhaul:

| Layer | Lifetime | Holds | Autoload |
|---|---|---|---|
| **Settings / results** | session | `player_count`, HUD/camera/music toggles, end-of-run `result_*` | `GameConfig` (existing) |
| **Run state** | one run (wiped on `reset()`) | `current_level`, `currency`, `owned_upgrades`, `owned_modifiers` | `RunState` (new) |
| **Meta** | persistent (`user://` save) | unlocked ships/daemons/skins, cleared Threat Level, achieved milestones | `MetaProgression` (new) |

`GameConfig` keeps the existing rule **"never write gameplay state to `GameConfig` mid-run"** — mid-run state belongs in `RunState`; persistent unlocks belong in `MetaProgression`. Both new autoloads are **no-`class_name`** singletons (same autoload-name conflict reason as `MusicManager`/`AdvancedConfig`).

---

## `RunState` autoload (`Autoloads/run_state.gd`)

The spine. Holds the current run; reset when a new run starts from `MainMenu`.

```gdscript
const MAX_LEVELS := 10
var current_level: int = 0          # 1..MAX_LEVELS during a run
var currency: int = 0               # Bits — single shared wallet
var owned_upgrades: Dictionary = {} # stat_key -> stack count
var owned_modifiers: Array = []     # Daemon ids (see Modifier system)

func reset() -> void                # zero everything; called by MainMenu on Start
func apply_to(entity: LivingEntity) -> void  # re-apply upgrades + daemons on each sector spawn
```

**Players are not persisted across scenes.** Each sector instantiates fresh `Player` entities (as today). On spawn, the level should call `RunState.apply_to(player)`, which re-derives stats from base and installs daemons — so the split-screen/camera wiring in `basic_level.gd` is untouched. `apply_to` reuses `XPComponent`'s existing machinery (`_base_stats` + `_apply_stat()` / `apply_power_up()`) for stat multipliers, and/or `AdvancedConfig.set_override(cls, prop, value)` for pre-`_ready()` application. **As built (P1):** `apply_to` is implemented — it looks each owned `stat_key` up in `PowerUpRegistry` and applies it once per stack — but is **not yet called** on spawn; that wiring lands in P3 with the Sandbox (until then `owned_upgrades` is always empty).

---

## Currency (working name: **Bits**)

Orbs become a spendable currency, **single shared wallet, banked on pickup** (co-op-friendly; matches the existing entity-less signal).

- **Unchanged:** `XPDropComponent` drops orbs on `entity_died`; `ExperienceOrb` magnet-collects and emits `EventBus.xp_collected(amount)`.
- **As built (P1):** `RunState` is the **sole** subscriber to `EventBus.xp_collected` (`run_state.gd`); it banks `int(amount)` into `RunState.currency` and emits `EventBus.currency_changed(total)` for the HUD. Banking lives in `RunState`, **not** `XPComponent`, because the pickup signal is entity-less — every player's `XPComponent` would otherwise double-count it into the shared wallet. `XPComponent` lost its XP/level state (`current_xp`, `current_level`, `base_xp_required`, `track_xp`, `_on_xp_collected`) and is now a pure stat-upgrade holder (`_base_stats` / `_bonuses` / `apply_power_up` / `get_projected_stat`).
- **As built (P1):** the in-run level-up is gone — the `player_leveled_up` and `xp_updated` signals were removed, and the `LevelUpUI` node was deleted from `basic_level.tscn`. `UI/LevelUpUI.tscn` + `level_up_ui.gd` are **kept** (the `player_leveled_up` connection neutered) so the card layout (P1 click / P2 arrow-nav) can be **refactored into the Sandbox shop**.

> The display string is centralized as `RunState.CURRENCY_NAME` (P1). A *full* rename of the class/file identifiers — `ExperienceOrb`, `XPComponent`, `XPDropComponent`, the `Experience Orbs` / `XP & Progression` groups in `AdvancedConfig.PROPERTY_DEFS` — is deferred; do it in one pass once the final name is locked.

---

## Objectives & exit portal

A small objective driver (a `LevelObjectiveComponent`, or inline in `basic_level.gd`) keyed off `RunState.current_level` decides the sector's win condition. **Varied + miniboss + final boss**:

| Sector | Objective |
|---|---|
| 1–9 (most) | kill quota **or** survive timer (rotate) |
| ~5 | **miniboss** (e.g. a Trojan or Rootkit) |
| 10 | **final boss** — the rogue AI / system core |

Track progress off existing signals: `EventBus.entity_died` for kill quotas (the HUD already counts kills via `last_attacker`), a frame timer for survival, boss-death for boss sectors. On completion: stop the spawner and spawn an **`ExitPort`** (`Area2D`) near the player. Player overlap → `MusicManager.stop()` → load the Sandbox. Surface objective progress on the HUD (reuse the kill/timer labels).

---

## Difficulty scaling

`RunState.current_level` parameterizes the existing flat systems (today both are fixed `@export`s):

- `EnemySpawnerComponent` — scale `spawn_interval` down and `max_enemies` up per sector; later, scale enemy stats.
- `ProcGenLevelComponent` — vary `arena_width/height`, `obstacle_density`, and seed per sector to give each one a distinct **sector** feel (filesystem → network → memory → registry → kernel).

Drive both from a single difficulty curve indexed by `current_level` (and later, by the selected **Threat Level**).

---

## Sandbox (the shop scene, `Levels/Sandbox/`)

A quarantined sector between fights — a full scene (not an overlay; the gameplay subviewports tear down cleanly between sectors). Built with the `LevelUpUI` / menu **dynamic-card pattern** + `UI/Themes/neon_theme.tres`.

- Lists purchasable **Upgrades** (generic stats) and **Daemons** (modifiers) with a Bits **cost**.
- Buying deducts `RunState.currency` and writes `owned_upgrades` / `owned_modifiers`.
- **Continue** → `RunState.current_level += 1` → next sector, or the **Win screen** if the final boss was just cleared.
- Co-op reuses `LevelUpUI`'s P1-click / P2-arrow-key dual input. Default: a **shared build** (purchases apply to both ships); per-ship builds are a possible later enhancement.

**Item model:** extend `PowerUpData` (`Resources/power_up_data.gd`) with a `cost: int` field and reuse `PowerUpRegistry`'s `_make()` pattern for the generic-upgrade catalog. Generic upgrades map to the `LivingEntity` stats (`livingEntity.gd:12-26`): `max_speed`, `acceleration`, `friction`, `turbo_speed_multiplier`, `max_health`, `fire_rate`, `bullet_damage`, `bullet_speed`.

---

## Bosses

A new boss entity type (a `LivingEntity` with a boss-behavior component and a high-HP `HealthComponent`), spawned by the objective driver instead of the normal spawner. Needs: multi-phase behavior, a boss-intro + on-screen **boss HP bar** UI hook, and a death that satisfies the sector objective. Miniboss ≈ sector 5; final boss = sector 10 (rogue AI). Defeating a boss is a natural **milestone** trigger (see below). See `docs/claude-ships.md` for how the ship-model scene pattern can be reused to build distinct boss visuals.

---

## Modifier system — **Daemons** (event-hook passives)

The Balatro-joker layer. *Daemon* = a background process that hooks your runtime — which is literally the design: each Daemon independently subscribes to shared **event points**, and effects **compose emergently**. There are **no hardcoded A+B=C combo tables**; synergy falls out of stacking hooks.

**Hook points** (several already exist as `EventBus` signals — reuse them; add new ones only where a hook must *mutate* gameplay rather than react):

| Hook | Source today | Notes |
|---|---|---|
| `on_shoot` | `EventBus.entity_shot` | to add/modify projectiles, a *pre-shoot* mutation hook is new |
| `on_hit` | (new) bullet→enemy hit | mutate damage, apply status |
| `on_kill` | `EventBus.entity_died` | filter by `last_attacker` == owner |
| `on_damage_taken` | `EventBus.entity_damaged` | reflect/negate, trigger on-hurt effects |
| `on_impact` | `EventBus.bullet_impacted` | FX / area effects |
| `on_process(delta)` | (new) per-frame tick | ramps, auras, regen |

**Wiring:** a `DaemonHost` component on the player owns the installed Daemons and routes hook calls. Reactive Daemons can subscribe to existing `EventBus` signals directly (filtering by owning entity, per the EventBus rule); mutating hooks (`on_shoot` projectile changes, `on_hit` damage changes) are called explicitly by `ShootComponent` / the bullet through the host so the result feeds back into gameplay. A `ModifierData` resource carries the metadata (`id`, `display_name`, `description`, `cost`, icon); the behavior is a small script implementing the relevant hook methods, registered in a `ModifierRegistry` autoload (mirrors `PowerUpRegistry`).

**Example Daemons (≈ first set):**

| Daemon | Hook | Effect |
|---|---|---|
| **Overclock** | `on_shoot` | every Nth shot fires a heavy piercing round |
| **Heuristic Scanner** | `on_hit` | bonus / crit damage vs. full-HP or not-recently-hit targets |
| **Quarantine** | `on_hit` | chance to freeze/slow the struck malware |
| **Fork Bomb** | `on_kill` | a kill spreads damage to nearby malware (chain/blast) |
| **Firewall** | `on_damage_taken` | chance to negate a hit and emit a reflective pulse |
| **Garbage Collector** | `on_kill` | kills drop extra Bits |

Emergent synergy, no special-casing: *Fork Bomb + Quarantine* = freezing chain blasts; *Overclock + Heuristic Scanner* = periodic heavy crits; stacking *Pierce + Bounce + Split* style daemons makes gloriously chaotic bullets.

---

## Meta-progression & save

Persistent, cross-run, **milestone-based** (no meta-currency, no hub-shop), and **variety, not power** — unlocks add options, never raw strength, so core-loop balance is untouched.

### `MetaProgression` autoload (`Autoloads/meta_progression.gd`)

```gdscript
var unlocked_ships: Array = []      # ship-model ids selectable on MainMenu
var unlocked_daemons: Array = []    # Daemon ids that can appear in Sandbox stock
var unlocked_skins: Array = []      # neon color / shader skin ids
var cleared_threat_level: int = 0   # highest Threat Level beaten
var achieved: Dictionary = {}       # milestone_id -> true

func record_run_end(won: bool) -> void  # evaluate milestones, unlock, save
func is_unlocked(kind, id) -> bool
```

On **every** run end (win or loss), `record_run_end()` checks milestones against the just-finished run and `MetaProgression` state, grants any new unlocks, and saves. `MainMenu` reads it to populate ship/skin selection and the Threat-Level picker.

### Milestones (examples)

| Milestone | Unlocks |
|---|---|
| Reach sector 5 | a new Daemon in the pool |
| Defeat the sector-5 miniboss | a new ship |
| First win (clear the rogue AI) | a skin + Threat Level 1 |
| Clear Threat Level *n* | Threat Level *n+1* |
| Lifetime kills ≥ X | a Daemon / skin |

### Threat Levels (difficulty ladder)

An **escalating** ladder (clear the current to unlock the next; Slay-the-Spire Ascension / Hades Heat style). A single integer raises the difficulty curve (spawn rate, enemy stats, objective targets). Selected on `MainMenu` next to ship/skin.

### Save layer

A `user://` `ConfigFile` (or save Resource) accessed through a tiny save util/autoload. **This is the same persistence layer the long-pending Settings-persistence todo needs** — build it once and have it also persist `GameConfig`'s HUD/camera/music toggles. Save on unlock and on settings change; load at startup.

### Unlockable content hooks
- **Ships / skins** — reuse the ship-model scene pattern (`Entities/Player/Ships/`, swap the `PlayerShip` child; see `docs/claude-ships.md`). Skins are `neon_color` / shader variants.
- **Daemons** — gate which `ModifierRegistry` entries can appear in Sandbox stock by `unlocked_daemons`.

---

## Naming glossary (working names — easy to swap)

| Concept | Working name | Alternatives |
|---|---|---|
| Currency (orbs) | **Bits** | Data Fragments, Cycles, Cache |
| Modifiers (jokers) | **Daemons** | Subroutines, Modules, Cores, Exploits |
| Generic upgrades | **Upgrades** | Patches, Drivers |
| Levels | **Sectors** | Layers, Nodes |
| Shop | **Sandbox** | Safe Node, Quarantine |
| Exit portal | **ExitPort** / Port | Gateway, Tunnel |
| Player health | **Integrity** | System Health |
| Difficulty ladder | **Threat Levels** | Quarantine Levels, Heuristic Levels |
| Meta hub (MainMenu) | **Mainframe** | Home Server, Desktop |
| Enemies | **malware** (Spyware = ranged, Worm/Bot = swarmer, Rootkit/Ransomware = tank, Virus = splitter) | — |
| Final boss | **rogue AI / system core** | The Kernel, Mainframe Core |

---

## Open design (decide as we build)

- **Random orb events** — honeypots (risk/reward Bit caches), a fleeing "data drone" worth a big payout, defend-the-beacon to decrypt a file, elite/golden malware, risk zones (more Bits, more danger).
- **Meta-currency hub** — a *possible later* upgrade to milestone-only unlocks if more player agency is wanted.
- **Co-op build model** — shared build now; per-ship builds later.
- **Content backlog** — full Daemon/Upgrade catalog, boss movesets, malware stat blocks, per-sector biomes. Track in `docs/todo.md`.
