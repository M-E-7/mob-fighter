extends Node
class_name HealthComponent
## Component that manages health state and emits signals on change

@export var entity: LivingEntity

var current_health: float
var max_health: float


func _ready() -> void:
	max_health = entity.max_health
	current_health = entity.starting_health


func take_damage(amount: float) -> void:
	current_health = max(current_health - amount, 0.0)
	EventBus.health_changed.emit(entity, current_health, max_health)
	if current_health <= 0.0:
		EventBus.entity_died.emit(entity)


func heal(amount: float) -> void:
	current_health = min(current_health + amount, max_health)
	EventBus.health_changed.emit(entity, current_health, max_health)
