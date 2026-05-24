extends Node

const _MUSIC_PATH := "res://Audio/Music/RisingHigh_AceCombat2.mp3"
const _BUS_NAME := "MusicAnalysis"

@export_group("Analysis")
@export_range(0.01, 0.5, 0.01) var smoothing: float = 0.10
@export_range(-80.0, -20.0, 1.0) var db_floor: float = -60.0

@export_group("Beat Detection")
@export_range(0.0, 3.0, 0.01) var onset_threshold: float = 0.12
@export_range(0.05, 2.0, 0.05) var beat_cooldown: float = 0.35

var bass: float = 0.0
var mid: float = 0.0
var treble: float = 0.0
var raw_bass: float = 0.0
var raw_mid: float = 0.0
var raw_treble: float = 0.0
var onset_energy: float = 0.0
var beat_cooldown_remaining: float = 0.0

var _player: AudioStreamPlayer
var _analyzer: AudioEffectSpectrumAnalyzerInstance
var _prev_raw_bass: float = 0.0
var _prev_raw_mid: float = 0.0
var _prev_raw_treble: float = 0.0


func _ready() -> void:
	AudioServer.add_bus()
	var bus_idx := AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(bus_idx, _BUS_NAME)
	AudioServer.set_bus_send(bus_idx, "Master")
	var effect := AudioEffectSpectrumAnalyzer.new()
	effect.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_1024
	AudioServer.add_bus_effect(bus_idx, effect)
	_analyzer = AudioServer.get_bus_effect_instance(bus_idx, 0) as AudioEffectSpectrumAnalyzerInstance

	var stream := load(_MUSIC_PATH) as AudioStreamMP3
	stream.loop = true
	_player = AudioStreamPlayer.new()
	_player.stream = stream
	_player.bus = _BUS_NAME
	add_child(_player)


func start() -> void:
	_player.play()


func stop() -> void:
	_player.stop()


func _process(delta: float) -> void:
	if not _analyzer:
		return

	raw_bass = _sample_band(20.0, 300.0)
	raw_mid = _sample_band(300.0, 2000.0)
	raw_treble = _sample_band(2000.0, 16000.0)

	bass = lerp(bass, raw_bass, smoothing)
	mid = lerp(mid, raw_mid, smoothing)
	treble = lerp(treble, raw_treble, smoothing)

	onset_energy = (
		maxf(0.0, raw_bass - _prev_raw_bass) +
		maxf(0.0, raw_mid - _prev_raw_mid) +
		maxf(0.0, raw_treble - _prev_raw_treble)
	)

	beat_cooldown_remaining = maxf(0.0, beat_cooldown_remaining - delta)

	if onset_energy > onset_threshold and beat_cooldown_remaining <= 0.0:
		EventBus.beat_detected.emit()
		beat_cooldown_remaining = beat_cooldown

	_prev_raw_bass = raw_bass
	_prev_raw_mid = raw_mid
	_prev_raw_treble = raw_treble


func _sample_band(from_hz: float, to_hz: float) -> float:
	var mag := _analyzer.get_magnitude_for_frequency_range(
		from_hz, to_hz, AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_AVERAGE
	)
	var db := linear_to_db(mag.length())
	return clampf((db - db_floor) / -db_floor, 0.0, 1.0)
