extends Node
class_name HealthComponent
## Component that manages health state and emits signals on change

# signal health_changed(current_health: float, max_health: float)
signal died

@export var entity: Entity
@export var healthDisplay: HealthDisplayComponent

var current_health: float
var max_health: float


func _ready() -> void:
	max_health = entity.max_health
	current_health = entity.starting_health


func take_damage(amount: float) -> void:
	current_health = max(current_health - amount, 0.0)
	# health_changed.emit(current_health, max_health)
	healthDisplay.healthUpdate(current_health, max_health)
	if current_health <= 0.0:
		died.emit()


func heal(amount: float) -> void:
	current_health = min(current_health + amount, max_health)
	# health_changed.emit(current_health, max_health)
	healthDisplay.healthUpdate(current_health, max_health)
