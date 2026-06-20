extends Node
class_name XPComponent

@export_group("References")
@export var entity: LivingEntity

var _bonuses: Dictionary = {}
var _base_stats: Dictionary = {}


func _ready() -> void:
	_base_stats = {
		"max_speed":    entity.max_speed,
		"fire_rate":    entity.fire_rate,
		"bullet_damage":entity.bullet_damage,
		"max_health":   entity.max_health,
		"bullet_speed": entity.bullet_speed,
	}


func apply_power_up(power_up: PowerUpData) -> void:
	_bonuses[power_up.stat_key] = _bonuses.get(power_up.stat_key, 0.0) + power_up.bonus_percent
	_apply_stat(power_up.stat_key)
	EventBus.power_up_applied.emit(entity, power_up)


func get_projected_stat(stat_key: String, additional_bonus: float) -> float:
	var base: float = _base_stats.get(stat_key, 0.0)
	var current_bonus: float = _bonuses.get(stat_key, 0.0)
	return base * (1.0 + current_bonus + additional_bonus)


func _apply_stat(stat_key: String) -> void:
	var base: float = _base_stats.get(stat_key, 0.0)
	var bonus: float = _bonuses.get(stat_key, 0.0)
	var new_val := base * (1.0 + bonus)
	entity.set(stat_key, new_val)
	if stat_key == "max_health" and entity.healthComponent:
		entity.healthComponent.max_health = new_val
