extends Node
class_name DaemonHostComponent
## Owns the live Daemon instances installed on its entity and routes hook calls to them.
## Reactive hooks come from EventBus (filtered by owning entity); mutating hooks (on_shoot/on_hit)
## are called synchronously by ShootComponent / Bullet via dispatch_shoot() / dispatch_hit().

@export var entity: LivingEntity

var _daemons: Array[Daemon] = []


func _ready() -> void:
	EventBus.entity_died.connect(_on_entity_died)
	EventBus.entity_damaged.connect(_on_entity_damaged)
	EventBus.bullet_impacted.connect(_on_bullet_impacted)


func _process(delta: float) -> void:
	for d: Daemon in _daemons:
		d.on_process(delta)


# --- Installation ---

## Currently installed Daemon instances (for the debug tuning UI).
func get_daemons() -> Array[Daemon]:
	return _daemons


## Rebuild the installed Daemons from RunState.owned_modifiers (called each sector via RunState.apply_to).
func install_from_run_state() -> void:
	for d: Daemon in _daemons:
		_free_daemon(d)
	_daemons.clear()
	for id: String in RunState.owned_modifiers:
		var data := ModifierRegistry.find(id)
		if data:
			_install(data, RunState.owned_modifiers[id])


## Live-install a single Daemon (debug grant). Replaces an existing instance of the same id.
func install_one(data: ModifierData, stacks: int) -> void:
	for i in range(_daemons.size() - 1, -1, -1):
		if _daemons[i].data == data:
			_free_daemon(_daemons[i])
			_daemons.remove_at(i)
	_install(data, stacks)


# --- Mutating hook dispatch ---

func dispatch_shoot(ctx: ShootContext) -> void:
	for d: Daemon in _daemons:
		d.on_shoot(ctx)


func dispatch_hit(ctx: HitContext) -> void:
	for d: Daemon in _daemons:
		d.on_hit(ctx)


# --- Reactive hook routing ---

func _on_entity_died(victim: LivingEntity) -> void:
	if not is_instance_valid(victim) or victim.last_attacker != entity:
		return
	for d: Daemon in _daemons:
		d.on_kill(victim)


func _on_entity_damaged(e: LivingEntity, amount: float) -> void:
	if e != entity:
		return
	for d: Daemon in _daemons:
		d.on_damage_taken(amount)


func _on_bullet_impacted(source: LivingEntity, world_pos: Vector2, dir: Vector2, color: Color) -> void:
	if source != entity:
		return
	for d: Daemon in _daemons:
		d.on_impact(world_pos, dir, color)


func _install(data: ModifierData, stacks: int) -> void:
	if not data.behavior_script:
		return
	var daemon: Daemon = data.behavior_script.new()
	daemon.name = data.id
	# add_child first so AdvancedConfig applies @export overrides before setup()/on_install() read them.
	add_child(daemon)
	daemon.setup(data, self, stacks)
	_daemons.append(daemon)
	daemon.on_install()


func _free_daemon(d: Daemon) -> void:
	d.on_uninstall()
	d.queue_free()
