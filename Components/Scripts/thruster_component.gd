extends Node2D
class_name ThrusterComponent

@export_group("References")
@export var entity: LivingEntity

@export_group("Settings")
@export_range(0.01, 0.5) var forward_threshold: float = 0.1
@export_range(0.01, 0.5) var strafe_threshold: float = 0.1
@export_range(0.5, 2.0) var base_brightness: float = 1.0
@export_range(0.0, 3.0) var music_bass_add: float = 0.6
@export_range(0.0, 5.0) var beat_spike_strength: float = 1.2
@export_range(0.05, 1.0) var beat_spike_decay: float = 0.15

var _beat_spike: float = 0.0
var _sockets: Array[ThrusterSocket] = []


func _ready() -> void:
	EventBus.beat_detected.connect(_on_beat_detected)
	for child in get_children():
		if child is ThrusterSocket:
			_sockets.append(child)


func _process(delta: float) -> void:
	if not entity or not entity.inputComponent:
		return

	_beat_spike = maxf(0.0, _beat_spike - delta / beat_spike_decay)

	var facing: Vector2 = Vector2.from_angle(entity.rotation - PI / 2.0)
	var move: Vector2 = entity.inputComponent.move_vector
	var forward_dot: float = move.dot(facing)
	var strafe_dot: float = move.dot(facing.rotated(PI / 2.0))

	var brightness: float = base_brightness + MusicManager.bass * music_bass_add + _beat_spike * beat_spike_strength

	var fire_main: bool = forward_dot > forward_threshold
	var fire_retro: bool = not fire_main and forward_dot < -forward_threshold
	var fire_left: bool = not fire_main and not fire_retro and strafe_dot > strafe_threshold
	var fire_right: bool = not fire_main and not fire_retro and strafe_dot < -strafe_threshold

	for socket in _sockets:
		socket.set_active(_socket_fires(socket, fire_main, fire_retro, fire_left, fire_right), brightness)


func _on_beat_detected() -> void:
	_beat_spike = 1.0


func _socket_fires(s: ThrusterSocket, main: bool, retro: bool, left: bool, right: bool) -> bool:
	match s.fire_when:
		ThrusterSocket.FireWhen.FORWARD:      return main
		ThrusterSocket.FireWhen.BACKWARD:     return retro
		ThrusterSocket.FireWhen.STRAFE_LEFT:  return left
		ThrusterSocket.FireWhen.STRAFE_RIGHT: return right
	return false
