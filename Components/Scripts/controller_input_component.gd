extends InputComponent
class_name ControllerInputComponent

@export_group("References")
@export var entity: LivingEntity

@export_group("Settings")
@export var device_id: int = 0
@export var move_dead_zone: float = 0.2
@export var aim_dead_zone: float = 0.2
@export var auto_aim_enabled: bool = true
@export var auto_aim_radius: float = 200.0
@export var auto_aim_half_angle_deg: float = 30.0

var _toggle_was_pressed: bool = false


func _process(_delta: float) -> void:
	if not entity:
		return

	var x := Input.get_joy_axis(device_id, JOY_AXIS_LEFT_X)
	var y := Input.get_joy_axis(device_id, JOY_AXIS_LEFT_Y)
	move_vector = Vector2(x, y)
	if move_vector.length() < move_dead_zone:
		move_vector = Vector2.ZERO

	shoot_pressed = Input.get_joy_axis(device_id, JOY_AXIS_TRIGGER_RIGHT) > 0.5

	var rx := Input.get_joy_axis(device_id, JOY_AXIS_RIGHT_X)
	var ry := Input.get_joy_axis(device_id, JOY_AXIS_RIGHT_Y)
	var stick := Vector2(rx, ry)
	if stick.length() > aim_dead_zone:
		aim_direction = stick.normalized()
		if auto_aim_enabled:
			aim_direction = _snap_to_enemy(aim_direction)

	var r_pressed := Input.is_joy_button_pressed(device_id, JOY_BUTTON_RIGHT_SHOULDER)
	if r_pressed and not _toggle_was_pressed:
		auto_aim_enabled = !auto_aim_enabled
	_toggle_was_pressed = r_pressed


func _snap_to_enemy(raw: Vector2) -> Vector2:
	var half_rad := deg_to_rad(auto_aim_half_angle_deg)
	var best: Node2D = null
	var best_angle := half_rad
	for e in entity.get_tree().get_nodes_in_group("enemy"):
		if not e is Node2D:
			continue
		var to_e: Vector2 = (e.global_position - entity.global_position)
		if to_e.length() > auto_aim_radius:
			continue
		var a := raw.angle_to(to_e.normalized())
		if abs(a) < best_angle:
			best_angle = abs(a)
			best = e
	if best:
		return (best.global_position - entity.global_position).normalized()
	return raw
