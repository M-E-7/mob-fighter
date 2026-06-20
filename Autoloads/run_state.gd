extends Node
## Run-scoped state for a single roguelike run; wiped on reset().
## No class_name — the autoload name IS the global identifier (same rule as MusicManager/AdvancedConfig).

var current_level: int = 0           # 1..MAX_LEVELS during a run; 0 outside a run
var currency: int = 0                # Bits — single shared wallet, banked on pickup
var owned_upgrades: Dictionary = {}  # stat_key -> stack count
var owned_modifiers: Array = []      # Daemon ids (P7)
var health_fraction: Array[float] = [1.0, 1.0]  # current HP as fraction of max, index 0=P1, 1=P2

const MAX_LEVELS := 10
const CURRENCY_NAME := "Bits"
const _ESCALATION := 0.5   # each extra stack multiplies base cost by (1 + 0.5 * stacks_owned)
const _REPAIR_AMOUNT := 0.34
const _REPAIR_BASE_COST := 10


func _ready() -> void:
	# Sole subscriber to the entity-less pickup signal, so the shared wallet is never double-counted.
	EventBus.xp_collected.connect(_on_xp_collected)


func reset() -> void:
	current_level = 0
	currency = 0
	owned_upgrades.clear()
	owned_modifiers.clear()
	health_fraction[0] = 1.0
	health_fraction[1] = 1.0
	EventBus.currency_changed.emit(currency)


func apply_to(entity: LivingEntity) -> void:
	# Re-apply purchased upgrades on each sector spawn.
	var xp := entity.get_node_or_null("XPComponent") as XPComponent
	if not xp:
		return
	for stat_key: String in owned_upgrades:
		var data := _find_upgrade(stat_key)
		if not data:
			continue
		for _i in int(owned_upgrades[stat_key]):
			xp.apply_power_up(data)


func upgrade_cost(data: PowerUpData) -> int:
	var stacks: int = owned_upgrades.get(data.stat_key, 0)
	return int(round(data.cost * (1.0 + _ESCALATION * stacks)))


func can_afford(cost: int) -> bool:
	return currency >= cost


func buy_upgrade(data: PowerUpData) -> bool:
	var cost := upgrade_cost(data)
	if not can_afford(cost):
		return false
	currency -= cost
	owned_upgrades[data.stat_key] = owned_upgrades.get(data.stat_key, 0) + 1
	EventBus.currency_changed.emit(currency)
	return true


func repair_cost() -> int:
	return _REPAIR_BASE_COST


func repair(player_count: int) -> bool:
	var cost := repair_cost()
	if not can_afford(cost):
		return false
	var needs_heal := false
	for i in min(player_count, health_fraction.size()):
		if health_fraction[i] < 1.0:
			needs_heal = true
			break
	if not needs_heal:
		return false
	currency -= cost
	for i in min(player_count, health_fraction.size()):
		health_fraction[i] = minf(health_fraction[i] + _REPAIR_AMOUNT, 1.0)
	EventBus.currency_changed.emit(currency)
	return true


func save_health(fractions: Array[float]) -> void:
	for i in min(fractions.size(), health_fraction.size()):
		health_fraction[i] = fractions[i]


func _on_xp_collected(amount: float) -> void:
	currency += int(amount)
	EventBus.currency_changed.emit(currency)


func _find_upgrade(stat_key: String) -> PowerUpData:
	for p: PowerUpData in PowerUpRegistry.power_ups:
		if p.stat_key == stat_key:
			return p
	return null
