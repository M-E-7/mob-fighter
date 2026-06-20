extends Node
## Run-scoped state for a single roguelike run; wiped on reset().
## No class_name — the autoload name IS the global identifier (same rule as MusicManager/AdvancedConfig).

var current_level: int = 0           # 1..MAX_LEVELS during a run; 0 outside a run
var currency: int = 0                # Bits — single shared wallet, banked on pickup
var owned_upgrades: Dictionary = {}  # stat_key -> stack count
var owned_modifiers: Array = []      # Daemon ids (P7)

const MAX_LEVELS := 10
const CURRENCY_NAME := "Bits"


func _ready() -> void:
	# Sole subscriber to the entity-less pickup signal, so the shared wallet is never double-counted.
	EventBus.xp_collected.connect(_on_xp_collected)


func reset() -> void:
	current_level = 0
	currency = 0
	owned_upgrades.clear()
	owned_modifiers.clear()
	EventBus.currency_changed.emit(currency)


func apply_to(entity: LivingEntity) -> void:
	# Re-apply purchased upgrades on each sector spawn. No-op until the Sandbox (P3) writes owned_upgrades.
	var xp := entity.get_node_or_null("XPComponent") as XPComponent
	if not xp:
		return
	for stat_key: String in owned_upgrades:
		var data := _find_upgrade(stat_key)
		if not data:
			continue
		for _i in int(owned_upgrades[stat_key]):
			xp.apply_power_up(data)


func _on_xp_collected(amount: float) -> void:
	currency += int(amount)
	EventBus.currency_changed.emit(currency)


func _find_upgrade(stat_key: String) -> PowerUpData:
	for p: PowerUpData in PowerUpRegistry.power_ups:
		if p.stat_key == stat_key:
			return p
	return null
