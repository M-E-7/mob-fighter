extends Node
class_name LevelObjectiveComponent
## Drives the sector win condition and spawns the ExitPort when met.
## Kill-quota mode for normal sectors; boss mode for sectors 5 and 10.
## In boss mode the normal spawner is stopped, the boss is spawned, and
## the ExitPort appears at the boss's death position.

@export var exit_port_scene: PackedScene
@export var boss_scene: PackedScene

@export_group("Objective")
@export var base_kill_quota: int = 20
@export var kill_quota_max: int = 60

@export_group("Boss")
@export var miniboss_sector: int = 5

@export_group("Exit Port")
@export var port_spawn_distance: float = 1500.0  # px from the player; the exit is a deliberate trek
@export var port_placement_attempts: int = 8     # directions tried to find a reachable spot
@export var port_open_search_radius: int = 12    # cells searched outward for a walkable cell

@export_group("On Complete")
@export var stop_spawner_on_complete: bool = false
@export var clear_enemies_on_complete: bool = false

var _spawner: EnemySpawnerComponent
var _astar: AStarGrid2D
var _cell_size: int = 32
var _arena_bounds: Vector2
var _target: int = 0
var _kills: int = 0
var _completed: bool = false

var _boss_mode: bool = false
var _active_boss: LivingEntity
var _boss_death_pos: Vector2


func _ready() -> void:
	add_to_group("level_objective")


func start(proc_gen: ProcGenLevelComponent, spawner: EnemySpawnerComponent) -> void:
	_spawner = spawner
	_astar = proc_gen.astar_grid
	_cell_size = proc_gen.cell_size
	_arena_bounds = Vector2(proc_gen.arena_width * proc_gen.cell_size, proc_gen.arena_height * proc_gen.cell_size)
	# P4 sets current_level from MainMenu; guard so a directly-launched sector still reads as 1.
	if RunState.current_level < 1:
		RunState.current_level = 1
	EventBus.entity_died.connect(_on_entity_died)
	if _is_boss_sector():
		_start_boss_mode()
	else:
		_start_kill_quota_mode()


func get_target() -> int:
	return _target


func get_progress() -> int:
	return _kills


func set_target(value: int) -> void:
	_target = max(value, 1)
	EventBus.objective_progress_changed.emit(_kills, _target)


func set_progress(value: int) -> void:
	_kills = max(value, 0)
	EventBus.objective_progress_changed.emit(_kills, _target)


func complete_now() -> void:
	if not _completed:
		_complete()


func spawn_boss_now() -> void:
	if _completed or is_instance_valid(_active_boss):
		return
	if not boss_scene:
		push_warning("LevelObjectiveComponent: boss_scene not set")
		return
	# Set boss mode before killing enemies so their deaths don't satisfy the kill quota.
	_boss_mode = true
	if is_instance_valid(_spawner):
		_spawner.stop()
	for e in get_tree().get_nodes_in_group("enemy"):
		var ent := e as LivingEntity
		if is_instance_valid(ent) and ent.healthComponent:
			ent.healthComponent.take_damage(1e9)
	_spawn_boss()


func _is_boss_sector() -> bool:
	return RunState.current_level == miniboss_sector or RunState.current_level >= RunState.MAX_LEVELS


func _start_boss_mode() -> void:
	if is_instance_valid(_spawner):
		_spawner.stop()
	_boss_mode = true
	_target = 1
	_kills = 0
	EventBus.objective_progress_changed.emit(0, 1)
	_spawn_boss()


func _start_kill_quota_mode() -> void:
	_boss_mode = false
	_target = int(round(lerpf(float(base_kill_quota), float(kill_quota_max), RunState.sector_t()) * RunState.threat_factor()))
	EventBus.objective_progress_changed.emit(_kills, _target)


func _spawn_boss() -> void:
	if not boss_scene:
		push_warning("LevelObjectiveComponent: boss_scene not set")
		return

	var boss: LivingEntity = boss_scene.instantiate()
	# add_child (not deferred): called from level_generated signal, outside any physics callback.
	get_parent().add_child(boss)
	boss.global_position = _pick_boss_position()

	# Scale HP after add_child so AdvancedConfig overrides have been applied,
	# then re-sync HealthComponent which caches entity.max_health in its own _ready().
	var boss_entity := boss as Boss
	if boss_entity:
		var t := RunState.sector_t()
		var tf := RunState.threat_factor()
		var eff_hp := lerpf(boss_entity.boss_health, boss_entity.boss_health_max, t) * tf
		boss.max_health = eff_hp
		if boss.healthComponent:
			boss.healthComponent.max_health = eff_hp
			boss.healthComponent.current_health = eff_hp

		var display_name: String
		var color: Color
		if RunState.current_level >= RunState.MAX_LEVELS:
			display_name = "ROGUE AI — SYSTEM CORE"
			color = Color(1.0, 0.1, 0.25, 1.0)
		else:
			display_name = "ROOTKIT"
			color = Color(0.5, 0.15, 1.0, 1.0)
		boss_entity.configure(display_name, color)
		_active_boss = boss
		EventBus.boss_spawned.emit(boss, display_name, eff_hp)
	else:
		_active_boss = boss
		EventBus.boss_spawned.emit(boss, "BOSS", boss.max_health)


func _on_entity_died(entity: LivingEntity) -> void:
	if _completed:
		return
	if _boss_mode:
		if is_instance_valid(_active_boss) and entity == _active_boss:
			_boss_death_pos = entity.global_position
			_complete()
	else:
		if not entity.is_in_group("enemy"):
			return
		_kills += 1
		EventBus.objective_progress_changed.emit(_kills, _target)
		if _kills >= _target:
			_complete()


func _complete() -> void:
	_completed = true
	if stop_spawner_on_complete and is_instance_valid(_spawner):
		_spawner.stop()
	if clear_enemies_on_complete:
		for e in get_tree().get_nodes_in_group("enemy"):
			(e as Node).queue_free()
	EventBus.sector_objective_completed.emit()
	_spawn_exit_port()


func _spawn_exit_port() -> void:
	if not exit_port_scene:
		return
	var port := exit_port_scene.instantiate()
	get_parent().add_child.call_deferred(port)
	var pos: Vector2
	if _boss_mode and _boss_death_pos != Vector2.ZERO:
		# Port appears at the boss's death site, snapped to a walkable cell.
		var cell := _nearest_open_cell(_world_to_cell(_boss_death_pos))
		pos = _cell_to_world(cell) if cell.x >= 0 else _boss_death_pos
	else:
		pos = _pick_port_position()
	port.set_deferred("global_position", pos)
	EventBus.exit_port_spawned.emit(port)


func _pick_boss_position() -> Vector2:
	var player := _get_player()
	var origin := player.global_position if is_instance_valid(player) else _arena_bounds * 0.5
	if _astar == null:
		return _clamp_to_bounds(origin + Vector2(300.0, 0.0))
	var from_cell := _nearest_open_cell(_world_to_cell(origin))
	if from_cell.x < 0:
		return _clamp_to_bounds(origin + Vector2(300.0, 0.0))
	var start_ang := randf() * TAU
	for i in 8:
		var ang := start_ang + TAU * float(i) / 8.0
		var target := _clamp_to_bounds(origin + Vector2.RIGHT.rotated(ang) * 600.0)
		var cell := _nearest_open_cell(_world_to_cell(target))
		if cell.x < 0:
			continue
		if not _astar.get_id_path(from_cell, cell).is_empty():
			return _cell_to_world(cell)
	return _cell_to_world(from_cell)


# Place the port a fixed distance from the player, snapped to a walkable cell that is actually
# path-reachable — so it can never spawn inside a wall or in an isolated pocket (soft-lock).
func _pick_port_position() -> Vector2:
	var player := _get_player()
	var origin := player.global_position if is_instance_valid(player) else _arena_bounds * 0.5
	if _astar == null:
		return _clamp_to_bounds(origin)
	var from_cell := _nearest_open_cell(_world_to_cell(origin))
	if from_cell.x < 0:
		return _clamp_to_bounds(origin)
	var start_ang := randf() * TAU
	for i in port_placement_attempts:
		var ang := start_ang + TAU * float(i) / float(port_placement_attempts)
		var target := _clamp_to_bounds(origin + Vector2.RIGHT.rotated(ang) * port_spawn_distance)
		var cell := _nearest_open_cell(_world_to_cell(target))
		if cell.x < 0:
			continue
		if not _astar.get_id_path(from_cell, cell).is_empty():
			return _cell_to_world(cell)
	# Fallback: an open cell next to the player (always reachable).
	return _cell_to_world(from_cell)


func _nearest_open_cell(cell: Vector2i) -> Vector2i:
	if _is_open(cell):
		return cell
	for radius in range(1, port_open_search_radius):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				if absi(dx) != radius and absi(dy) != radius:
					continue
				var c := cell + Vector2i(dx, dy)
				if _is_open(c):
					return c
	return Vector2i(-1, -1)


func _is_open(cell: Vector2i) -> bool:
	return _astar.is_in_boundsv(cell) and not _astar.is_point_solid(cell)


func _world_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(int(pos.x / _cell_size), int(pos.y / _cell_size))


func _cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * _cell_size + Vector2(_cell_size, _cell_size) * 0.5


func _clamp_to_bounds(pos: Vector2) -> Vector2:
	var margin := float(_cell_size) * 1.5
	return Vector2(clamp(pos.x, margin, _arena_bounds.x - margin), clamp(pos.y, margin, _arena_bounds.y - margin))


func _get_player() -> Node2D:
	for p in get_tree().get_nodes_in_group("player"):
		if p is Node2D:
			return p
	return null
