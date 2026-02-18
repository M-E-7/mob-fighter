extends InputComponent
class_name PlayerInputComponent

@export var entity: LivingEntity


func _process(_delta: float) -> void:
	if not entity:
		return

	move_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	shoot_pressed = Input.is_action_pressed("shoot")

	var mouse_pos := entity.get_global_mouse_position()
	aim_direction = (mouse_pos - entity.global_position).normalized()
