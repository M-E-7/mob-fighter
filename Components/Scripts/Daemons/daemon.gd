extends Node
class_name Daemon
## Base class for all Daemons (event-hook modifiers). Subclass and override the hooks you need;
## every hook defaults to a no-op so a Daemon only declares what it cares about.
## It is a Node (not RefCounted) so AdvancedConfig can override its @export tunables on node_added —
## the host add_child()s each Daemon before reading its values.

var data: ModifierData
var host: DaemonHostComponent
var entity: LivingEntity
var stacks: int = 1   # how many copies of this Daemon the player owns


func setup(d: ModifierData, h: DaemonHostComponent, stack_count: int) -> void:
	data = d
	host = h
	entity = h.entity
	stacks = stack_count
	# Optional per-entry overrides: a ModifierData.params key matching an @export var wins over its default.
	for key: String in data.params:
		if key in self:
			set(key, data.params[key])


# --- Hooks (override as needed) ---

func on_install() -> void:
	pass


func on_uninstall() -> void:
	pass


func on_shoot(_ctx: ShootContext) -> void:
	pass


func on_hit(_ctx: HitContext) -> void:
	pass


func on_kill(_victim: LivingEntity) -> void:
	pass


func on_damage_taken(_amount: float) -> void:
	pass


func on_impact(_world_pos: Vector2, _dir: Vector2, _color: Color) -> void:
	pass


func on_process(_delta: float) -> void:
	pass


# --- Helpers ---

func param(key: String, default: Variant) -> Variant:
	return data.params.get(key, default)
