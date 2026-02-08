extends Node
class_name MovementComponent
## Component that handles player movement input and physics
## Processes WASD/Arrow key input and applies smooth acceleration/deceleration

@export_group("Movement Settings")
@export var max_speed: float = 200.0
@export var acceleration: float = 1000.0
@export var friction: float = 800.0

var player: CharacterBody2D


func _ready() -> void:
	player = get_parent() as CharacterBody2D
	if not player:
		push_error("MovementComponent must be a child of CharacterBody2D")
	else:
		print("MovementComponent: Successfully connected to player")


func _physics_process(delta: float) -> void:
	if not player:
		return

	# Get input direction
	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# Debug output
	if input_vector.length() > 0:
		print("Input: ", input_vector, " | Velocity: ", player.velocity)

	if input_vector.length() > 0:
		# Apply acceleration toward target velocity
		var target_velocity := input_vector * max_speed
		player.velocity = player.velocity.move_toward(target_velocity, acceleration * delta)
	else:
		# Apply friction to slow down
		player.velocity = player.velocity.move_toward(Vector2.ZERO, friction * delta)

	# Move the player
	player.move_and_slide()
