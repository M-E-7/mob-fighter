extends Node2D
class_name ThrusterSocket

enum FireWhen { FORWARD, BACKWARD, STRAFE_LEFT, STRAFE_RIGHT }

@export_group("Settings")
@export var fire_when: FireWhen = FireWhen.FORWARD
@export var beam_color: Color = Color(0.356, 0.003, 0.027, 1.0)
@export var beam_length: float = 24.0
@export var beam_width: float = 8.0
@export_range(0.0, 1.0) var shimmer_strength: float = 0.25
@export_range(0.0, 30.0) var shimmer_speed: float = 8.0
@export_range(0.05, 2.0) var trail_duration: float = 0.4
@export_range(1.0, 12.0) var trail_radius: float = 3.0
@export_range(0.02, 1.0) var transition_time: float = 0.12

var _mesh_instance: MeshInstance2D
var _material: ShaderMaterial
var _time: float = 0.0
var _target_active: bool = false
var _transition: float = 0.0
var _target_scale_mult: float = 1.0
var _current_scale_mult: float = 1.0

var _trail_pos: Array[Vector2] = []
var _trail_time: Array[float] = []
var _last_sample_pos: Vector2 = Vector2.ZERO

const _SAMPLE_DIST: float = 3.0


func _ready() -> void:
	_mesh_instance = $BeamMesh

	var mesh := QuadMesh.new()
	mesh.size = Vector2(beam_width * 2.0, beam_length)
	_mesh_instance.mesh = mesh
	_mesh_instance.position = Vector2.ZERO

	_material = ShaderMaterial.new()
	_material.shader = load("res://Components/Shaders/thruster_beam.gdshader")
	_material.set_shader_parameter("beam_color", beam_color)
	_material.set_shader_parameter("shimmer_strength", shimmer_strength)
	_material.set_shader_parameter("shimmer_speed", shimmer_speed)
	_material.set_shader_parameter("brightness", 1.0)
	_mesh_instance.material = _material
	_mesh_instance.visible = false

	# Additive blending for the _draw() trail glow circles
	var canvas_mat := CanvasItemMaterial.new()
	canvas_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = canvas_mat


func _process(delta: float) -> void:
	var step := delta / transition_time
	if _target_active:
		_transition = minf(_transition + step, 1.0)
	else:
		_transition = maxf(_transition - step, 0.0)

	_current_scale_mult = move_toward(_current_scale_mult, _target_scale_mult, delta / transition_time)

	_mesh_instance.visible = _transition > 0.001
	if _mesh_instance.visible:
		var s := _transition * _current_scale_mult
		_mesh_instance.scale = Vector2(s, s)
		_mesh_instance.position.y = beam_length * 0.5 * s
		_mesh_instance.modulate.a = _transition

	if _transition > 0.001:
		_time += delta
		_material.set_shader_parameter("time_offset", _time)

		var wp: Vector2 = global_position
		if _target_active and (_trail_pos.is_empty() or wp.distance_to(_last_sample_pos) >= _SAMPLE_DIST):
			_trail_pos.append(wp)
			_trail_time.append(Time.get_ticks_msec() * 0.001)
			_last_sample_pos = wp

	_prune_trail()
	if not _trail_pos.is_empty():
		queue_redraw()


func _draw() -> void:
	if _trail_pos.is_empty():
		return
	var now: float = Time.get_ticks_msec() * 0.001
	for i: int in _trail_pos.size():
		var frac: float = 1.0 - clamp((now - _trail_time[i]) / trail_duration, 0.0, 1.0)
		if frac <= 0.0:
			continue
		var a: float = frac * frac  # quadratic — sharp near-end fade
		var lp: Vector2 = to_local(_trail_pos[i])
		draw_circle(lp, trail_radius * 2.2 * frac, Color(beam_color.r, beam_color.g, beam_color.b, a * 0.18))
		draw_circle(lp, trail_radius * frac,        Color(beam_color.r, beam_color.g, beam_color.b, a * 0.65))


func set_active(active: bool, brightness: float, scale_mult: float = 1.0) -> void:
	_target_active = active
	_target_scale_mult = scale_mult
	if active:
		_material.set_shader_parameter("brightness", brightness)


func _prune_trail() -> void:
	var cutoff: float = Time.get_ticks_msec() * 0.001 - trail_duration
	while not _trail_time.is_empty() and _trail_time[0] < cutoff:
		_trail_pos.remove_at(0)
		_trail_time.remove_at(0)
