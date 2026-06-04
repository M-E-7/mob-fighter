extends Node

const _BUS_NAME := "MusicAnalysis"
const _HISTORY_SIZE := 20
const _SONGS: Array = [
	{"path": "res://Audio/Music/RisingHigh_AceCombat2.mp3", "name": "Rising High — Ace Combat 2"},
]

signal song_changed(song_name: String)

@export_group("Analysis")
@export_range(0.01, 0.5, 0.01) var smoothing: float = 0.20
@export_range(-80.0, -20.0, 1.0) var db_floor: float = -60.0

@export_group("Beat Detection")
@export_range(0.0, 1.0, 0.01) var onset_threshold: float = 0.15
# @export_range(0.05, 2.0, 0.05) var beat_cooldown: float = 0.35
@export_range(0.05, 2.0, 0.05) var beat_cooldown: float = 0

var bass: float = 0.0
var mid: float = 0.0
var treble: float = 0.0
var raw_bass: float = 0.0
var raw_mid: float = 0.0
var raw_treble: float = 0.0
var onset_energy: float = 0.0
var beat_cooldown_remaining: float = 0.0
var current_song_index: int = 0

var _player: AudioStreamPlayer
var _analyzer: AudioEffectSpectrumAnalyzerInstance
var _bass_history: Array[float] = []
var _mid_history: Array[float] = []
var _treble_history: Array[float] = []


func _ready() -> void:
	AudioServer.add_bus()
	var bus_idx := AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(bus_idx, _BUS_NAME)
	AudioServer.set_bus_send(bus_idx, "Master")
	var effect := AudioEffectSpectrumAnalyzer.new()
	effect.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_1024
	AudioServer.add_bus_effect(bus_idx, effect)
	_analyzer = AudioServer.get_bus_effect_instance(bus_idx, 0) as AudioEffectSpectrumAnalyzerInstance

	_player = AudioStreamPlayer.new()
	_player.bus = _BUS_NAME
	add_child(_player)
	_load_current_song()


func start() -> void:
	_player.play()


func stop() -> void:
	_player.stop()


func current_song_name() -> String:
	return _SONGS[current_song_index]["name"]


func get_position() -> float:
	return _player.get_playback_position()


func get_duration() -> float:
	return _player.stream.get_length() if _player.stream else 0.0


func seek(position: float) -> void:
	_player.seek(clampf(position, 0.0, get_duration()))


func next_song() -> void:
	current_song_index = (current_song_index + 1) % _SONGS.size()
	_switch_song()


func prev_song() -> void:
	current_song_index = (current_song_index - 1 + _SONGS.size()) % _SONGS.size()
	_switch_song()


func _switch_song() -> void:
	var was_playing := _player.playing
	_player.stop()
	_load_current_song()
	if was_playing:
		_player.play()
	_bass_history.clear()
	_mid_history.clear()
	_treble_history.clear()
	song_changed.emit(current_song_name())


func _load_current_song() -> void:
	var stream := load(_SONGS[current_song_index]["path"]) as AudioStreamMP3
	stream.loop = true
	_player.stream = stream


func _process(delta: float) -> void:
	if not _analyzer:
		return

	raw_bass = _sample_band(20.0, 300.0)
	raw_mid = _sample_band(300.0, 2000.0)
	raw_treble = _sample_band(2000.0, 16000.0)

	bass = lerp(bass, raw_bass, smoothing)
	mid = lerp(mid, raw_mid, smoothing)
	treble = lerp(treble, raw_treble, smoothing)

	# Spectral flux: how much does current energy exceed recent local average per band
	_push_history(_bass_history, raw_bass)
	_push_history(_mid_history, raw_mid)
	_push_history(_treble_history, raw_treble)

	onset_energy = (
		maxf(0.0, raw_bass - _average(_bass_history)) +
		maxf(0.0, raw_mid - _average(_mid_history)) +
		maxf(0.0, raw_treble - _average(_treble_history))
	)

	beat_cooldown_remaining = maxf(0.0, beat_cooldown_remaining - delta)

	if onset_energy > onset_threshold and beat_cooldown_remaining <= 0.0:
		EventBus.beat_detected.emit()
		beat_cooldown_remaining = beat_cooldown


func _push_history(history: Array[float], value: float) -> void:
	history.append(value)
	if history.size() > _HISTORY_SIZE:
		history.pop_front()


func _average(history: Array[float]) -> float:
	if history.is_empty():
		return 0.0
	var sum := 0.0
	for v: float in history:
		sum += v
	return sum / history.size()


func _sample_band(from_hz: float, to_hz: float) -> float:
	var mag := _analyzer.get_magnitude_for_frequency_range(
		from_hz, to_hz, AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_AVERAGE
	)
	var db := linear_to_db(mag.length())
	return clampf((db - db_floor) / -db_floor, 0.0, 1.0)
