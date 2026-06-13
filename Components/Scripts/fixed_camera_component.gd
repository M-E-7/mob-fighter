extends Node
class_name FixedCameraComponent

@export var entity: LivingEntity

var camera: Camera2D
var _tracking: bool = true

const ROTATION_TRANSITION_SPEED := 10.0


func _ready() -> void:
	EventBus.entity_died.connect(_on_entity_died)


func _process(delta: float) -> void:
	if GameConfig.camera_relative_mode or camera == null:
		return
	camera.global_rotation = lerp_angle(camera.global_rotation, 0.0, 1.0 - exp(-ROTATION_TRANSITION_SPEED * delta))
	if absf(camera.global_rotation) < 0.001:
		camera.global_rotation = 0.0
		camera.ignore_rotation = true
	else:
		camera.ignore_rotation = false
	if _tracking and is_instance_valid(entity):
		camera.global_position = entity.global_position


func setup(p_entity: LivingEntity, p_camera: Camera2D) -> void:
	entity = p_entity
	camera = p_camera


func _on_entity_died(dead: LivingEntity) -> void:
	if dead == entity:
		_tracking = false
