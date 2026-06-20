extends Area2D
class_name ExitPort
## Sector exit gateway. Spawns when the objective is met; a player entering it ends the sector.

@export_group("Visuals")
@export var port_color: Color = Color(0.2, 1.0, 0.9)
@export var base_radius: float = 40.0
@export var pulse_speed: float = 4.0
@export var pulse_amount: float = 0.1
@export var halo_scale: float = 3.0          # beacon halo radius, as a multiple of base_radius
@export var spawn_scale_duration: float = 0.4

var _t: float = 0.0
var _triggered: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	scale = Vector2.ZERO
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, spawn_scale_duration)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var pulse := (1.0 - pulse_amount) + pulse_amount * sin(_t * pulse_speed)
	var r := base_radius * pulse
	var c := port_color
	# Large faint halo so the port reads as a beacon from across the arena (no off-screen indicator yet).
	draw_circle(Vector2.ZERO, r * halo_scale, Color(c.r, c.g, c.b, 0.05))
	draw_circle(Vector2.ZERO, r * 0.55, Color(c.r, c.g, c.b, 0.14))
	draw_arc(Vector2.ZERO, r * 0.75, 0.0, TAU, 64, c, 3.0, true)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, Color(c.r, c.g, c.b, 0.5), 6.0, true)


func _on_body_entered(body: Node2D) -> void:
	if _triggered or not body.is_in_group("player"):
		return
	_triggered = true
	EventBus.exit_port_entered.emit()
