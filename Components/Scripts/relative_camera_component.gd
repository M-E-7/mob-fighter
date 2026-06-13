extends Node
class_name RelativeCameraComponent

@export var entity: LivingEntity
@export var input_component: PlayerInputComponent

var camera: Camera2D
var _rel_cam_angle: float = 0.0
var _display_cam_angle: float = 0.0
var _look_ahead_angle: float = 0.0
var _tracking: bool = true
var _was_fixed: bool = false


func _ready() -> void:
	EventBus.entity_died.connect(_on_entity_died)


func _process(delta: float) -> void:
	if not GameConfig.camera_relative_mode or camera == null:
		_was_fixed = true
		return
	camera.ignore_rotation = false
	if _was_fixed:
		_display_cam_angle = camera.global_rotation
		_look_ahead_angle = camera.global_rotation
		_was_fixed = false
	var rot_w := 1.0 - exp(-GameConfig.camera_smoothing * delta)
	_display_cam_angle = lerp_angle(_display_cam_angle, _rel_cam_angle, rot_w)
	camera.global_rotation = _display_cam_angle
	if _tracking and is_instance_valid(entity):
		var la_w := 1.0 - exp(-GameConfig.camera_look_ahead_smoothing * delta)
		_look_ahead_angle = lerp_angle(_look_ahead_angle, _rel_cam_angle, la_w)
		var fwd := Vector2(sin(_look_ahead_angle), -cos(_look_ahead_angle))
		camera.global_position = entity.global_position + fwd * GameConfig.camera_look_ahead
	if input_component:
		input_component.relative_camera_angle = _rel_cam_angle


func _unhandled_input(event: InputEvent) -> void:
	if not GameConfig.camera_relative_mode:
		return
	if event is InputEventMouseMotion:
		_rel_cam_angle += (event as InputEventMouseMotion).relative.x * GameConfig.mouse_sensitivity


func setup(p_entity: LivingEntity, p_camera: Camera2D, p_input: PlayerInputComponent) -> void:
	entity = p_entity
	camera = p_camera
	input_component = p_input


func _on_entity_died(dead: LivingEntity) -> void:
	if dead == entity:
		_tracking = false
