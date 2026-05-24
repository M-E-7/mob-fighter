extends Node
class_name MusicVisualsComponent

@export_group("References")
@export var entity: LivingEntity
@export var neon_component: NeonShaderComponent

@export_group("Band Influence")
@export_range(0.0, 1.0, 0.01) var intensity_scale: float = 1.0
@export_range(0.0, 5.0, 0.1) var bass_glow_add: float = 1.8
@export_range(0.0, 10.0, 0.1) var mid_pulse_add: float = 5.0
@export_range(0.0, 0.5, 0.01) var treble_feather_add: float = 0.13
@export_range(0.0, 1.0, 0.05) var max_pulse_amount: float = 0.5

@export_group("Beat Spike")
@export_range(0.0, 5.0, 0.1) var beat_spike_strength: float = 1.5
@export_range(0.05, 2.0, 0.05) var beat_spike_decay: float = 0.3

var _base_glow: float = 0.0
var _base_pulse: float = 0.0
var _base_feather: float = 0.0
var _beat_spike: float = 0.0


func _ready() -> void:
	if neon_component:
		_base_glow = neon_component.glow_intensity
		_base_pulse = neon_component.pulse_speed
		_base_feather = neon_component.glow_feather
	EventBus.beat_detected.connect(_on_beat_detected)


func _process(delta: float) -> void:
	if not GameConfig.music_visuals_enabled or not neon_component:
		return

	_beat_spike = maxf(0.0, _beat_spike - delta / beat_spike_decay)

	var glow: float = lerp(_base_glow, _base_glow + bass_glow_add, MusicManager.bass * intensity_scale) + _beat_spike * beat_spike_strength
	var pulse_spd: float = lerp(_base_pulse, _base_pulse + mid_pulse_add, MusicManager.mid * intensity_scale)
	var feather: float = lerp(_base_feather, _base_feather + treble_feather_add, MusicManager.treble * intensity_scale)
	var pulse_amt: float = lerp(0.0, max_pulse_amount, (MusicManager.bass + MusicManager.mid) * 0.5 * intensity_scale)

	neon_component.set_visual_params(glow, pulse_spd, feather, pulse_amt)


func _on_beat_detected() -> void:
	_beat_spike = 1.0
