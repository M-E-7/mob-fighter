extends Daemon
class_name DaemonArmor
## on_install: pure stat tradeoff — slower but tankier. Applies through XPComponent so it composes
## with Upgrades and re-applies cleanly each sector; on_uninstall reverses it for live debug re-grants.

@export_group("Hardened Kernel")
@export var speed_mult: float = -0.25  ## fraction change to max_speed per stack (negative = slower)
@export var health_mult: float = 0.5   ## fraction change to max_health per stack

var _speed_applied: float = 0.0
var _health_applied: float = 0.0


func on_install() -> void:
	var xp := entity.get_node_or_null("XPComponent") as XPComponent
	if not xp:
		return
	_speed_applied = speed_mult * stacks
	_health_applied = health_mult * stacks
	xp.apply_stat_bonus("max_speed", _speed_applied)
	xp.apply_stat_bonus("max_health", _health_applied)


func on_uninstall() -> void:
	var xp := entity.get_node_or_null("XPComponent") as XPComponent
	if not xp:
		return
	xp.apply_stat_bonus("max_speed", -_speed_applied)
	xp.apply_stat_bonus("max_health", -_health_applied)
	_speed_applied = 0.0
	_health_applied = 0.0
