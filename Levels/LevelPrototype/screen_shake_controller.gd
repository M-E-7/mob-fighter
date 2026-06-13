extends Node
class_name ScreenShakeController

@export_group("Trauma")
@export_range(0.0, 1.0, 0.05) var kill_trauma: float = 0.2
@export_range(0.0, 1.0, 0.05) var hurt_trauma: float = 0.35
@export_range(0.5, 5.0, 0.1) var trauma_decay: float = 1.8

@export_group("Shake")
@export_range(0.0, 40.0, 0.5) var max_offset: float = 14.0
@export_range(1.0, 60.0, 0.5) var shake_frequency: float = 28.0
@export_range(100.0, 2000.0, 50.0) var distance_falloff: float = 600.0

var _cameras: Array[Camera2D] = []
var _players: Array[LivingEntity] = []
var _trauma: Array[float] = []
var _noise: FastNoiseLite
var _time: float = 0.0


func _ready() -> void:
	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = 1.0
	EventBus.entity_died.connect(_on_entity_died)
	EventBus.entity_damaged.connect(_on_entity_damaged)


func _process(delta: float) -> void:
	_time += delta
	for i in _cameras.size():
		if not is_instance_valid(_cameras[i]):
			continue
		_trauma[i] = maxf(0.0, _trauma[i] - trauma_decay * delta)
		if _trauma[i] <= 0.0:
			_cameras[i].offset = Vector2.ZERO
			continue
		# Quadratic trauma keeps small hits subtle and big moments violent.
		var shake := _trauma[i] * _trauma[i]
		_cameras[i].offset = Vector2(
			_noise.get_noise_2d(_time * shake_frequency, 17.0) * max_offset * shake,
			_noise.get_noise_2d(53.0, _time * shake_frequency) * max_offset * shake
		)


func setup(cameras: Array[Camera2D], players: Array[LivingEntity]) -> void:
	_cameras = cameras
	_players = players
	_trauma.clear()
	for camera in cameras:
		_trauma.append(0.0)


func add_trauma(camera_index: int, amount: float) -> void:
	if camera_index < _trauma.size():
		_trauma[camera_index] = minf(1.0, _trauma[camera_index] + amount)


func _on_entity_died(entity: LivingEntity) -> void:
	if not entity.is_in_group("enemy"):
		return
	for i in _players.size():
		if i >= _trauma.size() or not is_instance_valid(_players[i]):
			continue
		var dist := entity.global_position.distance_to(_players[i].global_position)
		var falloff := clampf(1.0 - dist / distance_falloff, 0.0, 1.0)
		add_trauma(i, kill_trauma * falloff)


func _on_entity_damaged(entity: LivingEntity, _amount: float) -> void:
	var idx := _players.find(entity)
	if idx >= 0:
		add_trauma(idx, hurt_trauma)
