extends Node
class_name FacingComponent
## Component that tracks which direction the player is facing
## Updates based on movement direction and emits signals for animation/combat systems

signal facing_changed(direction: Vector2)

@export var update_on_movement: bool = true

var facing_direction: Vector2 = Vector2.DOWN


func _physics_process(_delta: float) -> void:
	if not update_on_movement:
		return

	# Get input direction to update facing
	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# Only update facing if there's actual movement input
	if input_vector.length() > 0:
		var new_direction := input_vector.normalized()
		if new_direction != facing_direction:
			facing_direction = new_direction
			facing_changed.emit(facing_direction)


## Get facing direction as a string (useful for animation state names)
func get_facing_as_string() -> String:
	if abs(facing_direction.x) > abs(facing_direction.y):
		return "right" if facing_direction.x > 0 else "left"
	else:
		return "down" if facing_direction.y > 0 else "up"


## Check if facing horizontally (left or right)
func is_facing_horizontal() -> bool:
	return abs(facing_direction.x) > abs(facing_direction.y)


## Check if facing vertically (up or down)
func is_facing_vertical() -> bool:
	return abs(facing_direction.y) > abs(facing_direction.x)
