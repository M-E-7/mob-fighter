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
	print("Entity _ready() called")
	print("Movement component exists: ", movementComponent != null)
	# print("Facing component exists: ", facing != null)


## Get the movement component
# func get_movement_component() -> MovementComponent:
# 	return movement


## Get the facing component
# func get_facing_component() -> FacingComponent:
# 	return facing
