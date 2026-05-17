extends InputComponent
class_name PlayerInputComponent

@export_group("References")
@export var entity: LivingEntity
@export var target_viewport: SubViewport


func _process(_delta: float) -> void:
	if not entity:
		return

	move_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	shoot_pressed = Input.is_action_pressed("shoot")

	var world_mouse: Vector2
	if target_viewport:
		var sv_mouse := target_viewport.get_mouse_position()
		world_mouse = target_viewport.canvas_transform.affine_inverse() * sv_mouse
	else:
		world_mouse = entity.get_global_mouse_position()

	aim_direction = (world_mouse - entity.global_position).normalized()
