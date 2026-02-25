extends InputComponent
class_name EnemyInputComponent

@export var entity: LivingEntity

var player: Node2D

var _proc_gen: ProcGenLevelComponent
var _path: PackedVector2Array = []
var _path_index: int = 0
var _recalc_timer: float = 0.0

const RECALC_INTERVAL := 0.5
const WAYPOINT_REACH_DISTANCE := 12.0


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")


func _process(delta: float) -> void:
	if not entity or not player:
		return

	aim_direction = (player.global_position - entity.global_position).normalized()
	shoot_pressed = true

	# Lazy-find the proc gen component (it may not exist at _ready time)
	if not _proc_gen:
		_proc_gen = get_tree().get_first_node_in_group("proc_gen") as ProcGenLevelComponent

	if not _proc_gen or not _proc_gen.astar_grid:
		move_vector = aim_direction
		return

	_recalc_timer -= delta
	if _recalc_timer <= 0.0 or _path.is_empty():
		_recalc_timer = RECALC_INTERVAL
		_recalculate_path()

	_follow_path()


func _recalculate_path() -> void:
	_path_index = 0
	var cs := _proc_gen.cell_size

	var from := Vector2i(
		clampi(int(entity.global_position.x / cs), 0, _proc_gen.arena_width - 1),
		clampi(int(entity.global_position.y / cs), 0, _proc_gen.arena_height - 1)
	)
	var to := Vector2i(
		clampi(int(player.global_position.x / cs), 0, _proc_gen.arena_width - 1),
		clampi(int(player.global_position.y / cs), 0, _proc_gen.arena_height - 1)
	)

	var cell_path := _proc_gen.astar_grid.get_id_path(from, to)
	_path = PackedVector2Array()
	for cell in cell_path:
		_path.append(Vector2((cell.x + 0.5) * cs, (cell.y + 0.5) * cs))


func _follow_path() -> void:
	if _path.is_empty() or _path_index >= _path.size():
		move_vector = Vector2.ZERO
		return

	var target := _path[_path_index]
	if entity.global_position.distance_to(target) < WAYPOINT_REACH_DISTANCE:
		_path_index += 1
		if _path_index >= _path.size():
			move_vector = Vector2.ZERO
			return
		target = _path[_path_index]

	move_vector = (target - entity.global_position).normalized()
