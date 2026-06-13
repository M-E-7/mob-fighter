extends Node
class_name LevelVisualsController

@export_group("Background")
@export_range(0.0, 1.0, 0.01) var grid_intensity: float = 0.22
@export_range(0.0, 2.0, 0.05) var star_intensity: float = 1.0
@export_range(0.0, 1.0, 0.01) var nebula_strength: float = 0.45
@export_range(64.0, 1024.0, 16.0) var grid_size: float = 256.0

@export_group("Wall Edge Colors")
@export var wall_edge_base: Color = Color(0.2, 0.5, 0.8, 0.8)
@export var wall_edge_bass: Color = Color(0.0, 0.9, 1.0, 1.0)
@export var wall_edge_mid: Color = Color(0.6, 0.3, 1.0, 1.0)
@export var wall_edge_treble: Color = Color(1.0, 0.5, 0.1, 1.0)
@export var wall_edge_beat: Color = Color(1.0, 1.0, 1.0, 1.0)

@export_group("Wall Glow")
@export_range(0.0, 1.0, 0.01) var wall_glow_base: float = 0.20
@export_range(0.0, 1.0, 0.01) var wall_glow_peak: float = 0.80
@export_range(1.0, 3.0, 0.1) var wall_edge_overbright: float = 1.6

@export_group("Wall Pulse")
@export_range(0.0, 1.0, 0.01) var wall_pulse_amount: float = 0.40
@export_range(0.1, 2.0, 0.1) var wall_pulse_speed_base: float = 0.5
@export_range(0.1, 8.0, 0.1) var wall_pulse_speed_peak: float = 4.0

@export_group("Timing")
@export_range(0.0, 1.0, 0.01) var mid_influence: float = 0.55
@export_range(0.05, 2.0, 0.05) var beat_flash_decay: float = 0.25

var _bg_rects: Array[ColorRect] = []
var _cameras: Array[Camera2D] = []
var _proc_gen: ProcGenLevelComponent
var _beat_flash: float = 0.0


func setup(rects: Array[ColorRect], proc_gen: ProcGenLevelComponent, cameras: Array[Camera2D]) -> void:
	_bg_rects = rects
	_cameras = cameras
	_proc_gen = proc_gen
	add_to_group("level_visuals_controller")
	EventBus.beat_detected.connect(_on_beat_detected)


func _process(delta: float) -> void:
	_update_backgrounds()

	if not GameConfig.music_visuals_enabled:
		return

	_beat_flash = maxf(0.0, _beat_flash - delta / beat_flash_decay)

	if _proc_gen:
		# Bass → color brightness, Mid → color tint, Treble → color tint, Beat → flash
		var edge_col := wall_edge_base.lerp(wall_edge_bass, MusicManager.bass)
		edge_col = edge_col.lerp(wall_edge_mid, MusicManager.mid * mid_influence)
		edge_col = edge_col.lerp(wall_edge_treble, MusicManager.treble)
		edge_col = edge_col.lerp(wall_edge_beat, _beat_flash)

		# Bass → base glow alpha; Mid → oscillating pulse on top
		var glow_a: float = lerpf(wall_glow_base, wall_glow_peak, MusicManager.bass)
		var pulse_speed: float = lerpf(wall_pulse_speed_base, wall_pulse_speed_peak, MusicManager.mid)
		var pulse: float = (sin(Time.get_ticks_msec() * 0.001 * pulse_speed * TAU) * 0.5 + 0.5) * wall_pulse_amount
		glow_a = clampf(glow_a + pulse * MusicManager.mid, 0.0, 1.0)

		# Overbright rgb survives self_modulate in the HDR canvas and feeds bloom.
		edge_col.r *= wall_edge_overbright
		edge_col.g *= wall_edge_overbright
		edge_col.b *= wall_edge_overbright
		_proc_gen.update_wall_visuals(edge_col, glow_a)


func _on_beat_detected() -> void:
	_beat_flash = 1.0


# Camera uniforms must be pushed every frame regardless of the music toggle —
# the background shader reconstructs world space from them.
func _update_backgrounds() -> void:
	for i in _bg_rects.size():
		if i >= _cameras.size() or not is_instance_valid(_cameras[i]):
			continue
		var mat := _bg_rects[i].material as ShaderMaterial
		if not mat:
			continue
		var cam := _cameras[i]
		mat.set_shader_parameter("cam_pos", cam.get_screen_center_position())
		mat.set_shader_parameter("cam_rot", cam.global_rotation)
		mat.set_shader_parameter("cam_zoom", cam.zoom.x)
		mat.set_shader_parameter("grid_intensity", grid_intensity)
		mat.set_shader_parameter("star_intensity", star_intensity)
		mat.set_shader_parameter("nebula_strength", nebula_strength)
		mat.set_shader_parameter("grid_size", grid_size)
