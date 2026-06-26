extends Node
## Run-scoped state for a single roguelike run; wiped on reset().
## No class_name — the autoload name IS the global identifier (same rule as MusicManager/AdvancedConfig).

var current_level: int = 0           # 1..MAX_LEVELS during a run; 0 outside a run
var currency: int = 0                # Bits — single shared wallet, banked on pickup
var owned_upgrades: Dictionary = {}  # stat_key -> stack count
var owned_modifiers: Dictionary = {} # Daemon id -> stack count (P7)
var health_fraction: Array[float] = [1.0, 1.0]  # current HP as fraction of max, index 0=P1, 1=P2
var run_kills: Array[int] = [0, 0]   # cumulative kills per player across all sectors
var run_time: float = 0.0            # cumulative seconds across all sectors
var threat_level: int = 0            # P9 Threat-Level ladder; 0 = normal until MetaProgression wires the selector

const MAX_LEVELS := 10
const CURRENCY_NAME := "Bits"
const _ESCALATION := 0.5   # each extra stack multiplies base cost by (1 + 0.5 * stacks_owned)
const _REPAIR_AMOUNT := 0.34
const _REPAIR_BASE_COST := 10
const _THREAT_STEP := 0.15  # each Threat Level adds 15% difficulty on top of the sector curve


func _ready() -> void:
	# Sole subscriber to the entity-less pickup signal, so the shared wallet is never double-counted.
	EventBus.xp_collected.connect(_on_xp_collected)


## Linear 0→1 progress through the sector count; used to lerp difficulty curves.
func sector_t() -> float:
	var lvl := clampi(current_level, 1, MAX_LEVELS)
	return float(lvl - 1) / float(MAX_LEVELS - 1)


## Multiplier applied on top of the sector curve; 1.0 at threat 0.
func threat_factor() -> float:
	return 1.0 + _THREAT_STEP * float(threat_level)


func reset() -> void:
	current_level = 0
	currency = 0
	owned_upgrades.clear()
	owned_modifiers.clear()
	health_fraction[0] = 1.0
	health_fraction[1] = 1.0
	run_kills[0] = 0
	run_kills[1] = 0
	run_time = 0.0
	threat_level = 0
	EventBus.currency_changed.emit(currency)


func add_sector_stats(kills1: int, kills2: int, time: float) -> void:
	run_kills[0] += kills1
	run_kills[1] += kills2
	run_time += time


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

	# Install Daemons AFTER upgrades so their stat bonuses layer on the same XP path.
	var host := entity.get_node_or_null("DaemonHostComponent") as DaemonHostComponent
	if host:
		host.install_from_run_state()


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


func modifier_stacks(id: String) -> int:
	return owned_modifiers.get(id, 0)


func modifier_cost(data: ModifierData) -> int:
	var stacks: int = owned_modifiers.get(data.id, 0)
	return int(round(data.cost * (1.0 + _ESCALATION * stacks)))


func can_buy_modifier(data: ModifierData) -> bool:
	if data.max_stacks != 0 and modifier_stacks(data.id) >= data.max_stacks:
		return false
	return can_afford(modifier_cost(data))


func buy_modifier(data: ModifierData) -> bool:
	if not can_buy_modifier(data):
		return false
	currency -= modifier_cost(data)
	owned_modifiers[data.id] = owned_modifiers.get(data.id, 0) + 1
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
