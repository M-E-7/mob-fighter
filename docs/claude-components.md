# Components & Entities — authoring guide

> Extension of the root `CLAUDE.md`. Read this when creating a new component or entity. Project conventions and the master gotcha list live in `CLAUDE.md`.

## Creating a New Component

### Files to create

| File | Path |
|---|---|
| Script | `Components/Scripts/<snake_case_name>.gd` |
| Scene | `Components/<PascalCaseName>.tscn` |

### Script template

```gdscript
extends Node
class_name MyComponent

@export_group("References")
@export var entity: LivingEntity

@export_group("Settings")
@export var some_value: float = 1.0

func _ready() -> void:
    pass

func do_something(delta: float) -> void:
    if not entity:
        return
```

### Rules

- `extends Node` unless the component needs physics (`CharacterBody2D`, `Area2D`, etc.) **or has `Node2D` children** (particles, sprites) — use `extends Node2D` in that case. A plain `Node` root breaks the canvas item hierarchy and makes visual children invisible.
- Always declare `class_name` matching the PascalCase filename.
- Always export `entity: LivingEntity` — the component reads all tuneable values from it.
- Use `@export_group` to separate the entity reference from tunable settings.
- The component scene root is the component node itself. Add children only when the component genuinely needs them (UI nodes, CollisionShape2D, etc.).
- After creating the scene, add the component as a child node inside the entity's scene and link it via the entity's matching `@export` field in the inspector.

### Wiring to an entity

1. Open the entity's `.tscn`.
2. Add the component scene as a child.
3. In the entity's exported properties, assign the new child node to the corresponding `@export var` field.
4. If `LivingEntity` doesn't have the field yet, add it under the appropriate `@export_group("Components")` block.

---

## Creating a New Entity

- Inherit from `living_entity.tscn` (scene inheritance) or from `LivingEntity` in script.
- Place all files in a dedicated folder: `Entities/<EntityName>/`.
- The entity script coordinates components only — no game logic belongs in it.
- All tuneable values (speed, health, damage, etc.) are `@export` on the entity, consumed by components.
- Entity scenes follow the established node layout:

```
EntityName (LivingEntity / CharacterBody2D)
├── CollisionShape2D
├── HurtboxComponent (Area2D)
│   └── CollisionShape2D
├── HealthComponent
├── HealthDisplayComponent
├── InputComponent variant
├── MovementComponent
├── ShootComponent
└── Visual node (Sprite2D / MeshInstance2D)
```

Player entities use a ship model scene instead of a bare visual node:

```
Player (LivingEntity)
├── CollisionShape2D        ← shape overwritten from ship.collision_shape at runtime
├── PlayerInputComponent
├── MovementComponent
├── ShootComponent
├── XPComponent
├── MusicVisualsComponent
└── PlayerShip (ShipModel)  ← instance of Entities/Player/Ships/PlayerShip.tscn
    ├── SpriteDisplay (Sprite2D)
    ├── NeonShaderComponent
    └── ThrusterComponent
        ├── MainSocket (ThrusterSocket)
        └── … (one ThrusterSocket per nozzle)
```

See `docs/claude-ships.md` for the ship model scene internals.
