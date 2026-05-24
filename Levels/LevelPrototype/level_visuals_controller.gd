extends Node
class_name LevelVisualsController

@export_group("Background Colors")
@export var base_color: Color = Color(0.04, 0.04, 0.06)
@export var bass_peak_color: Color = Color(0.10, 0.08, 0.14)
@export var mid_tint_color: Color = Color(0.09, 0.05, 0.11)
@export var beat_flash_color: Color = Color(0.16, 0.12, 0.20)

@export_group("Wall Edge Colors")
@export var wall_edge_base: Color = Color(0.2, 0.5, 0.8, 0.8)
@export var wall_edge_bass: Color = Color(0.0, 0.9, 1.0, 1.0)
@export var wall_edge_mid: Color = Color(0.6, 0.3, 1.0, 1.0)
@export var wall_edge_beat: Color = Color(1.0, 1.0, 1.0, 1.0)

@export_group("Wall Glow")
@export_range(0.0, 1.0, 0.01) var wall_glow_base: float = 0.10
@export_range(0.0, 1.0, 0.01) var wall_glow_peak: float = 0.45

@export_group("Timing")
@export_range(0.0, 1.0, 0.01) var mid_influence: float = 0.35
@export_range(0.05, 2.0, 0.05) var beat_flash_decay: float = 0.25

var _bg_rects: Array[ColorRect] = []
var _proc_gen: ProcGenLevelComponent
var _beat_flash: float = 0.0


func setup(rects: Array[ColorRect], proc_gen: ProcGenLevelComponent) -> void:
	_bg_rects = rects
	_proc_gen = proc_gen
	EventBus.beat_detected.connect(_on_beat_detected)


func _process(delta: float) -> void:
	if not GameConfig.music_visuals_enabled:
		return

	_beat_flash = maxf(0.0, _beat_flash - delta / beat_flash_decay)

	var bg_color := base_color.lerp(bass_peak_color, MusicManager.bass)
	bg_color = bg_color.lerp(mid_tint_color, MusicManager.mid * mid_influence)
	bg_color = bg_color.lerp(beat_flash_color, _beat_flash)

	for rect: ColorRect in _bg_rects:
		rect.color = bg_color

	if _proc_gen:
		var edge_col := wall_edge_base.lerp(wall_edge_bass, MusicManager.bass)
		edge_col = edge_col.lerp(wall_edge_mid, MusicManager.mid * mid_influence)
		edge_col = edge_col.lerp(wall_edge_beat, _beat_flash)
		var glow_a: float = lerpf(wall_glow_base, wall_glow_peak, MusicManager.bass)
		_proc_gen.update_wall_visuals(edge_col, glow_a)


func _on_beat_detected() -> void:
	_beat_flash = 1.0
