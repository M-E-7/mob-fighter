extends Node
class_name LevelObjectiveComponent
## Drives the sector win condition (kill-quota for now) and spawns the ExitPort when met.
## Keyed off RunState.current_level so later sectors can vary the objective type.

@export var exit_port_scene: PackedScene

@export_group("Objective")
@export var base_kill_quota: int = 20

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


func start(proc_gen: ProcGenLevelComponent, spawner: EnemySpawnerComponent) -> void:
	_spawner = spawner
	_astar = proc_gen.astar_grid
	_cell_size = proc_gen.cell_size
	_arena_bounds = Vector2(proc_gen.arena_width * proc_gen.cell_size, proc_gen.arena_height * proc_gen.cell_size)
	# P4 sets current_level from MainMenu; guard so a directly-launched sector still reads as 1.
	if RunState.current_level < 1:
		RunState.current_level = 1
	_target = base_kill_quota
	EventBus.entity_died.connect(_on_entity_died)
	EventBus.objective_progress_changed.emit(_kills, _target)


func _on_entity_died(entity: LivingEntity) -> void:
	if _completed or not entity.is_in_group("enemy"):
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
	port.set_deferred("global_position", _pick_port_position())


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
