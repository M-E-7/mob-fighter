extends Node
class_name MovementComponent
## Component that handles player movement input and physics
## Processes WASD/Arrow key input and applies smooth acceleration/deceleration

# @export_group("Movement Settings")
# @export var max_speed: float = 200.0
# @export var acceleration: float = 1000.0
# @export var friction: float = 800.0

# var player: CharacterBody2D
@export var entity: Player


func _ready() -> void:
	pass
	# player = get_parent() as CharacterBody2D
	# if not player:
	# 	push_error("MovementComponent must be a child of CharacterBody2D")
	# else:
	# 	print("MovementComponent: Successfully connected to player")


func _physics_process(delta: float) -> void:
	if not entity:
		return

	# Get input direction
	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# Debug output
	if input_vector.length() > 0:
		print("Input: ", input_vector, " | Velocity: ", entity.velocity)

	if input_vector.length() > 0:
		# Apply acceleration toward target velocity
		var target_velocity : Variant = input_vector * entity.max_speed
		entity.velocity = entity.velocity.move_toward(target_velocity, entity.acceleration * delta)
	else:
		# Apply friction to slow down
		entity.velocity = entity.velocity.move_toward(Vector2.ZERO, entity.friction * delta)

	# Move the player
	entity.move_and_slide()
