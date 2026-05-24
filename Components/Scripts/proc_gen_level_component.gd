extends Node
class_name ProcGenLevelComponent

signal level_generated(spawn_position: Vector2)

@export_group("Arena Settings")
@export var arena_width: int = 40
@export var arena_height: int = 30
@export var cell_size: int = 32

@export_group("Obstacle Settings")
@export_range(0.0, 1.0) var obstacle_density: float = 0.3
@export var clear_radius: float = 4.0
@export var noise_frequency: float = 0.1

@export_group("Seed")
@export var randomize_seed: bool = true
@export var gen_seed: int = 0

## The center of the arena — place the player here after generation
var spawn_position: Vector2
## Grid-based pathfinding map, available after level_generated fires
var astar_grid: AStarGrid2D

var _container: Node2D
var _noise: FastNoiseLite
var _renderer: WallRenderer
var _outline_renderer: WallOutlineRenderer


# Draws filled wall rectangles — geometry is fixed after generation
class WallRenderer extends Node2D:
	var wall_rects: Array[Rect2] = []
	var wall_color: Color = Color(0.25, 0.25, 0.3)

	func _draw() -> void:
		for rect in wall_rects:
			draw_rect(rect, wall_color)


# Draws only the outer perimeter edges of wall groups as white lines.
# Color is driven via self_modulate — no queue_redraw() needed per frame.
class WallOutlineRenderer extends Node2D:
	var line_width: float = 2.5

	func compute_from_grid(grid: Array, w: int, h: int, cs: int) -> void:
		# Collect all wall→empty boundary edges as line segments
		var segments: Array[PackedVector2Array] = []
		for y in range(h):
			for x in range(w):
				if not grid[y][x]:
					continue
				var x0 := x * cs
				var y0 := y * cs
				var x1 := x0 + cs
				var y1 := y0 + cs
				if x == 0 or not grid[y][x - 1]:
					var seg := PackedVector2Array([Vector2(x0, y0), Vector2(x0, y1)])
					segments.append(seg)
				if x == w - 1 or not grid[y][x + 1]:
					var seg := PackedVector2Array([Vector2(x1, y0), Vector2(x1, y1)])
					segments.append(seg)
				if y == 0 or not grid[y - 1][x]:
					var seg := PackedVector2Array([Vector2(x0, y0), Vector2(x1, y0)])
					segments.append(seg)
				if y == h - 1 or not grid[y + 1][x]:
					var seg := PackedVector2Array([Vector2(x0, y1), Vector2(x1, y1)])
					segments.append(seg)
		set_meta("segments", segments)
		queue_redraw()

	func _draw() -> void:
		if not has_meta("segments"):
			return
		var segments: Array[PackedVector2Array] = get_meta("segments")
		for seg in segments:
			draw_line(seg[0], seg[1], Color.WHITE, line_width, true)


func _ready() -> void:
	add_to_group("proc_gen")
	generate.call_deferred()


func generate() -> void:
	_clear()
	_setup_noise()
	_create_container()
	spawn_position = Vector2(arena_width * cell_size * 0.5, arena_height * cell_size * 0.5)
	_build_level()
	level_generated.emit(spawn_position)


func _clear() -> void:
	if _container:
		_container.queue_free()
		_container = null
	_renderer = null
	_outline_renderer = null


func _setup_noise() -> void:
	_noise = FastNoiseLite.new()
	if randomize_seed:
		gen_seed = randi()
	_noise.seed = gen_seed
	_noise.frequency = noise_frequency
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH


func _create_container() -> void:
	_container = Node2D.new()
	_container.name = "GeneratedLevel"
	get_parent().add_child(_container)


func _build_level() -> void:
	var grid := _build_grid()
	var processed := _make_bool_grid(false)

	# Single physics body for all walls
	var body := StaticBody2D.new()
	body.name = "Walls"

	# Single renderer — one _draw() call for all walls
	_renderer = WallRenderer.new()
	_renderer.name = "WallRenderer"
	var merged_rects: Array[Rect2] = []

	# Greedy rectangle merging: collapse adjacent wall cells into large rectangles
	for y in range(arena_height):
		for x in range(arena_width):
			if not grid[y][x] or processed[y][x]:
				continue

			# Extend right
			var w := 1
			while x + w < arena_width and grid[y][x + w] and not processed[y][x + w]:
				w += 1

			# Extend down at this width
			var h := 1
			var can_extend := true
			while can_extend and y + h < arena_height:
				for dx in range(w):
					if not grid[y + h][x + dx] or processed[y + h][x + dx]:
						can_extend = false
						break
				if can_extend:
					h += 1

			# Mark all covered cells as processed
			for dy in range(h):
				for dx in range(w):
					processed[y + dy][x + dx] = true

			var rect_size := Vector2(w * cell_size, h * cell_size)
			var rect_pos := Vector2(x * cell_size, y * cell_size)

			var shape := CollisionShape2D.new()
			var rect_shape := RectangleShape2D.new()
			rect_shape.size = rect_size
			shape.shape = rect_shape
			shape.position = rect_pos + rect_size * 0.5
			body.add_child(shape)

			merged_rects.append(Rect2(rect_pos, rect_size))

	_renderer.wall_rects = merged_rects

	# Outline renderer: computed from raw grid to get true group perimeters
	_outline_renderer = WallOutlineRenderer.new()
	_outline_renderer.name = "WallOutlineRenderer"
	_outline_renderer.compute_from_grid(grid, arena_width, arena_height, cell_size)

	_container.add_child(body)
	_container.add_child(_renderer)
	_container.add_child(_outline_renderer)
	_build_astar(grid)


func _build_astar(grid: Array) -> void:
	astar_grid = AStarGrid2D.new()
	astar_grid.region = Rect2i(0, 0, arena_width, arena_height)
	astar_grid.cell_size = Vector2(cell_size, cell_size)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar_grid.update()

	for y in range(arena_height):
		for x in range(arena_width):
			if grid[y][x]:
				astar_grid.set_point_solid(Vector2i(x, y))


func update_wall_visuals(edge_col: Color, glow_a: float) -> void:
	if not _outline_renderer:
		return
	# Modulate alpha by glow strength; self_modulate is GPU-side — no redraw needed
	var c := edge_col
	c.a = clampf(glow_a + edge_col.a * 0.5, 0.0, 1.0)
	_outline_renderer.self_modulate = c


func _build_grid() -> Array:
	var grid: Array = []
	var center := Vector2(arena_width * 0.5, arena_height * 0.5)

	for y in range(arena_height):
		var row: Array = []
		for x in range(arena_width):
			var is_border := x == 0 or x == arena_width - 1 or y == 0 or y == arena_height - 1
			if is_border:
				row.append(true)
			elif Vector2(x, y).distance_to(center) < clear_radius:
				row.append(false)
			else:
				var noise_val: float = (_noise.get_noise_2d(x, y) + 1.0) * 0.5
				row.append(noise_val > (1.0 - obstacle_density))
		grid.append(row)

	return grid


func _make_bool_grid(value: bool) -> Array:
	var grid: Array = []
	for y in range(arena_height):
		var row: Array = []
		for x in range(arena_width):
			row.append(value)
		grid.append(row)
	return grid
