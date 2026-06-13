extends Area2D
class_name ExperienceOrb

@export_group("Settings")
@export var xp_value: float = 1.0
@export var pickup_radius: float = 80.0
@export var attract_speed: float = 200.0
@export var lifetime: float = 8.0

@export_group("Visuals")
@export var orb_visual: Node2D
@export var trail_color: Color = Color(1.0, 0.85, 0.2, 1.0)
@export_range(0.0, 1.0, 0.05) var trail_duration: float = 0.35
@export_range(0.0, 10.0, 0.5) var trail_radius: float = 4.0

var _player: Node2D
var _attracting: bool = false
var _collected: bool = false

var _trail_pos: PackedVector2Array = PackedVector2Array()
var _trail_time: PackedFloat32Array = PackedFloat32Array()
var _last_sample: Vector2 = Vector2.INF
var _trail_dirty: bool = false

const _SAMPLE_DIST := 3.0


func _ready() -> void:
	_player = _get_nearest_player()
	var timer := get_tree().create_timer(lifetime)
	timer.timeout.connect(_on_lifetime_expired)
	# Additive blending for the _draw() trail only — OrbMesh has its own material.
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat
	if orb_visual:
		var base := orb_visual.scale
		orb_visual.scale = base * 0.05
		var tween := create_tween()
		tween.tween_property(orb_visual, "scale", base, 0.3) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_update_trail()
	if _collected:
		return

	if not is_instance_valid(_player):
		_player = _get_nearest_player()
		if not is_instance_valid(_player):
			return

	var dist := global_position.distance_to(_player.global_position)

	if dist <= pickup_radius:
		_attracting = true

	if _attracting:
		if dist < 6.0:
			_collect()
			return
		var dir := (_player.global_position - global_position).normalized()
		global_position += dir * attract_speed * delta


func _draw() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	for i in _trail_pos.size():
		var frac := 1.0 - (now - _trail_time[i]) / trail_duration
		if frac <= 0.0:
			continue
		var local := to_local(_trail_pos[i])
		var col := Color(trail_color.r, trail_color.g, trail_color.b, frac * frac * 0.18)
		draw_circle(local, trail_radius * 2.2 * frac, col)
		col.a = frac * frac * 0.65
		draw_circle(local, trail_radius * frac, col)


func _on_lifetime_expired() -> void:
	if _collected:
		return
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)


func _collect() -> void:
	_collected = true
	EventBus.xp_collected.emit(xp_value)
	EventBus.xp_orb_collected.emit(global_position, xp_value)
	queue_free()


func _get_nearest_player() -> Node2D:
	var nearest: Node2D = null
	var nearest_dist := INF
	for p in get_tree().get_nodes_in_group("player"):
		if not p is Node2D:
			continue
		var d := global_position.distance_to(p.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = p
	return nearest


func _update_trail() -> void:
	if _attracting and not _collected:
		_sample_trail()
	_prune_trail()
	if _trail_pos.size() > 0:
		queue_redraw()
		_trail_dirty = true
	elif _trail_dirty:
		_trail_dirty = false
		queue_redraw()


func _sample_trail() -> void:
	if _last_sample != Vector2.INF and global_position.distance_to(_last_sample) < _SAMPLE_DIST:
		return
	_last_sample = global_position
	_trail_pos.append(global_position)
	_trail_time.append(Time.get_ticks_msec() / 1000.0)


func _prune_trail() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	while _trail_time.size() > 0 and now - _trail_time[0] > trail_duration:
		_trail_time.remove_at(0)
		_trail_pos.remove_at(0)
