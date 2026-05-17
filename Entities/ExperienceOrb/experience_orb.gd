extends Area2D
class_name ExperienceOrb

@export_group("Settings")
@export var xp_value: float = 1.0
@export var pickup_radius: float = 80.0
@export var attract_speed: float = 200.0
@export var lifetime: float = 8.0

var _player: Node2D
var _attracting: bool = false
var _collected: bool = false


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	var timer := get_tree().create_timer(lifetime)
	timer.timeout.connect(_on_lifetime_expired)


func _process(delta: float) -> void:
	if _collected or not is_instance_valid(_player):
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


func _on_lifetime_expired() -> void:
	if _collected:
		return
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)


func _collect() -> void:
	_collected = true
	EventBus.xp_collected.emit(xp_value)
	queue_free()
