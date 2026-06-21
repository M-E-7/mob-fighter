extends Control
class_name ExitPortIndicator
## Edge-pinned arrow + distance readout pointing toward the off-screen ExitPort.
## Hides itself once the port scrolls on-screen (the port's own halo takes over).

@export_group("Indicator")
@export var color: Color = Color(0.3, 1.6, 1.4, 1.0)   # overbright cyan; the root HUD is HDR, so it blooms
@export var edge_margin: float = 64.0
@export var arrow_length: float = 34.0
@export var arrow_width: float = 28.0
@export var label_offset: float = 40.0
@export var distance_per_unit: float = 32.0            # px per displayed "m" (one arena cell)

var _player: LivingEntity
var _subviewport: SubViewport
var _container: Control
var _port: Node2D

var _edge_pos: Vector2 = Vector2.ZERO
var _angle: float = 0.0
var _shown: bool = false

var _label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = $DistanceLabel
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_color", color)
	EventBus.exit_port_spawned.connect(_on_exit_port_spawned)
	_set_shown(false)


func setup(player: LivingEntity, subviewport: SubViewport, container: Control) -> void:
	_player = player
	_subviewport = subviewport
	_container = container


func _process(_delta: float) -> void:
	if not visible:
		return
	if not (is_instance_valid(_port) and _port.is_inside_tree() and is_instance_valid(_player) and _subviewport):
		_set_shown(false)
		return

	var screen_px := _container.global_position + _subviewport.get_canvas_transform() * _port.global_position
	var vp_size := Vector2(_subviewport.size)
	var rect := Rect2(_container.global_position + Vector2(edge_margin, edge_margin), vp_size - Vector2(edge_margin, edge_margin) * 2.0)

	# Port on-screen → let its own halo do the work.
	if rect.has_point(screen_px):
		_set_shown(false)
		return

	var center := _container.global_position + vp_size * 0.5
	var dir := screen_px - center
	if dir.length_squared() < 0.001:
		return
	_edge_pos = _ray_to_rect_edge(center, dir, rect)
	_angle = dir.angle()
	_set_shown(true)

	var dist := _player.global_position.distance_to(_port.global_position)
	_label.text = "%d m" % roundi(dist / distance_per_unit)
	_label.reset_size()
	_label.position = _edge_pos - dir.normalized() * label_offset - _label.size * 0.5
	queue_redraw()


func _draw() -> void:
	if not _shown:
		return
	# Chevron pointing toward +X, rotated to _angle (screen-space direction to the port).
	var pts := PackedVector2Array([
		Vector2(arrow_length * 0.5, 0.0),
		Vector2(-arrow_length * 0.5, -arrow_width * 0.5),
		Vector2(-arrow_length * 0.2, 0.0),
		Vector2(-arrow_length * 0.5, arrow_width * 0.5),
	])
	var outline := PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]])
	draw_set_transform(_edge_pos, _angle, Vector2.ONE)
	draw_colored_polygon(pts, color)
	draw_polyline(outline, Color(color.r * 1.3, color.g * 1.3, color.b * 1.3, 1.0), 2.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _on_exit_port_spawned(port: ExitPort) -> void:
	_port = port


func _set_shown(value: bool) -> void:
	if _shown == value:
		return
	_shown = value
	_label.visible = value
	queue_redraw()


# Cast a ray from the (in-rect) center toward dir and return where it meets the rect edge.
func _ray_to_rect_edge(center: Vector2, dir: Vector2, rect: Rect2) -> Vector2:
	var t := INF
	if absf(dir.x) > 0.0001:
		var bx := rect.end.x if dir.x > 0.0 else rect.position.x
		t = minf(t, (bx - center.x) / dir.x)
	if absf(dir.y) > 0.0001:
		var by := rect.end.y if dir.y > 0.0 else rect.position.y
		t = minf(t, (by - center.y) / dir.y)
	return center + dir * t
