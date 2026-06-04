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
@export_range(0.0, 5.0) var turbo_brightness_add: float = 1.5

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

	var local_move: Vector2 = entity.inputComponent.move_vector
	var turbo: bool = entity.inputComponent.thrust_pressed

	var fire_main: bool = local_move.y < -forward_threshold or turbo
	var fire_retro: bool = local_move.y > forward_threshold
	var fire_strafe_left: bool = local_move.x > strafe_threshold
	var fire_strafe_right: bool = local_move.x < -strafe_threshold

	var brightness: float = base_brightness + MusicManager.bass * music_bass_add + _beat_spike * beat_spike_strength
	var main_brightness: float = brightness + (turbo_brightness_add if turbo else 0.0)

	for socket in _sockets:
		var active := _socket_fires(socket, fire_main, fire_retro, fire_strafe_left, fire_strafe_right)
		var sock_brightness := main_brightness if socket.fire_when == ThrusterSocket.FireWhen.FORWARD else brightness
		socket.set_active(active, sock_brightness)


func _on_beat_detected() -> void:
	_beat_spike = 1.0


func _socket_fires(s: ThrusterSocket, main: bool, retro: bool, left: bool, right: bool) -> bool:
	match s.fire_when:
		ThrusterSocket.FireWhen.FORWARD:      return main
		ThrusterSocket.FireWhen.BACKWARD:     return retro
		ThrusterSocket.FireWhen.STRAFE_LEFT:  return left
		ThrusterSocket.FireWhen.STRAFE_RIGHT: return right
	return false
