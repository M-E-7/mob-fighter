extends Node
class_name HealthDisplayComponent
## Component that displays a red health bar below the entity

var bar_width: float = 30.0
var bar_height: float = 4.0
var bar_offset: Vector2 = Vector2(-15, 12)

var bg_bar: ColorRect
var hp_bar: ColorRect


func _ready() -> void:
	bg_bar = ColorRect.new()
	bg_bar.size = Vector2(bar_width, bar_height)
	bg_bar.position = bar_offset
	bg_bar.color = Color(0.2, 0.2, 0.2)
	get_parent().add_child.call_deferred(bg_bar)

	hp_bar = ColorRect.new()
	hp_bar.size = Vector2(bar_width, bar_height)
	hp_bar.position = bar_offset
	hp_bar.color = Color(0.8, 0.1, 0.1)
	get_parent().add_child.call_deferred(hp_bar)

	EventBus.health_changed.connect(_on_health_changed)


func _on_health_changed(entity: Node, current_health: float, max_health: float) -> void:
	if entity == owner and max_health > 0.0:
		hp_bar.size.x = bar_width * (current_health / max_health)
