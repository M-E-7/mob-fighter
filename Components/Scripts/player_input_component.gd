extends InputComponent
class_name PlayerInputComponent

@export_group("References")
@export var entity: LivingEntity
@export var target_viewport: SubViewport

@export_group("Settings")
@export_range(1.0, 30.0, 0.5) var turn_speed: float = 8.0


func _process(delta: float) -> void:
	if not entity:
		return

	move_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	shoot_pressed = Input.is_action_pressed("shoot")
	thrust_pressed = Input.is_action_pressed("thrust_forward")

	var world_mouse: Vector2
	if target_viewport:
		var sv_mouse := target_viewport.get_mouse_position()
		world_mouse = target_viewport.canvas_transform.affine_inverse() * sv_mouse
	else:
		world_mouse = entity.get_global_mouse_position()

	var mouse_dir := (world_mouse - entity.global_position).normalized()
	var target_angle := mouse_dir.angle() + PI / 2.0
	entity.rotation += clamp(angle_difference(entity.rotation, target_angle), -turn_speed * delta, turn_speed * delta)
	aim_direction = Vector2.from_angle(entity.rotation - PI / 2.0)
