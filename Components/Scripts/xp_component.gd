extends Node
class_name XPComponent

@export_group("References")
@export var entity: LivingEntity

@export_group("Settings")
@export var base_xp_required: float = 10.0
@export var track_xp: bool = true

var current_xp: float = 0.0
var current_level: int = 0

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
	if track_xp:
		EventBus.xp_collected.connect(_on_xp_collected)


func _on_xp_collected(amount: float) -> void:
	current_xp += amount
	var required := base_xp_required * pow(2.0, float(current_level))
	if current_xp >= required:
		current_xp -= required
		current_level += 1
		EventBus.player_leveled_up.emit(entity)
	required = base_xp_required * pow(2.0, float(current_level))
	EventBus.xp_updated.emit(entity, current_xp, required, current_level)


func apply_power_up(power_up: PowerUpData) -> void:
	_bonuses[power_up.stat_key] = _bonuses.get(power_up.stat_key, 0.0) + power_up.bonus_percent
	_apply_stat(power_up.stat_key)
	EventBus.power_up_applied.emit(entity, power_up)


func _apply_stat(stat_key: String) -> void:
	var base: float = _base_stats.get(stat_key, 0.0)
	var bonus: float = _bonuses.get(stat_key, 0.0)
	var new_val := base * (1.0 + bonus)
	entity.set(stat_key, new_val)
	if stat_key == "max_health" and entity.healthComponent:
		entity.healthComponent.max_health = new_val
