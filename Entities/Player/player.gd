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

# @onready var movement: MovementComponent = $MovementComponent
# @onready var facing: FacingComponent = $FacingComponent


func _ready() -> void:
	add_to_group("player")
	if healthComponent:
		healthComponent.died.connect(queue_free)
	if hurtboxComponent:
		hurtboxComponent.damaged.connect(take_damage)


func take_damage(amount: float) -> void:
	if healthComponent:
		healthComponent.take_damage(amount)
