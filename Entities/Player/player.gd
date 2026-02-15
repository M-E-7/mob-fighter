extends CharacterBody2D
class_name Entity
## Entity coordinator that manages components
## Provides clean API for external systems to access player components

@export_group("Movement Settings")
@export var healthComponent: HealthComponent
@export var healthDisplayComponent: HealthDisplayComponent
@export var max_speed: float = 200.0
@export var acceleration: float = 1000.0
@export var friction: float = 800.0

@export_group("Health Settings")
@export var movementComponent: PlayerMovementComponent
@export var hurtboxComponent: HurtboxComponent
@export var max_health: float = 100.0
@export var starting_health: float = 100.0

@export_group("Shooting Settings")
@export var playerShootComponent: PlayerShootComponent
@export var fire_rate: float = 5.0
@export var bullet_damage: float = 10.0


func _ready() -> void:
	add_to_group("player")
	EventBus.entity_died.connect(_on_entity_died)
	EventBus.entity_damaged.connect(_on_entity_damaged)


func _on_entity_died(entity: Node) -> void:
	if entity == self:
		queue_free()


func _on_entity_damaged(entity: Node, amount: float) -> void:
	if entity == self and healthComponent:
		healthComponent.take_damage(amount)
