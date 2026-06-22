extends Node
class_name EnemySpawnerComponent

@export var enemy_scene: PackedScene

@export_group("Spawn Settings")
@export var spawn_interval: float = 2.0
@export var max_enemies: int = 20
@export var spawn_interval_min: float = 0.6
@export var max_enemies_max: int = 60

@export_group("Enemy Scaling")
@export var enemy_health_mult_max: float = 2.0
@export var enemy_damage_mult_max: float = 1.6
@export var enemy_speed_mult_max: float = 1.3

var _proc_gen: ProcGenLevelComponent
var _arena_bounds: Vector2
var _spawn_timer: float = 0.0
var _active: bool = false
var _eff_spawn_interval: float = 2.0
var _eff_max_enemies: int = 20
var _enemy_health_mult: float = 1.0
var _enemy_damage_mult: float = 1.0
var _enemy_speed_mult: float = 1.0


func start(proc_gen: ProcGenLevelComponent) -> void:
	_proc_gen = proc_gen
	_arena_bounds = Vector2(
		proc_gen.arena_width * proc_gen.cell_size,
		proc_gen.arena_height * proc_gen.cell_size
	)
	var t := RunState.sector_t()
	var tf := RunState.threat_factor()
	# spawn_interval ramps down (harder = faster); divide by threat_factor.
	_eff_spawn_interval = lerpf(spawn_interval, spawn_interval_min, t) / tf
	_eff_max_enemies = int(round(lerpf(float(max_enemies), float(max_enemies_max), t) * tf))
	_enemy_health_mult = lerpf(1.0, enemy_health_mult_max, t) * tf
	_enemy_damage_mult = lerpf(1.0, enemy_damage_mult_max, t) * tf
	_enemy_speed_mult = lerpf(1.0, enemy_speed_mult_max, t) * tf
	_active = true


func stop() -> void:
	_active = false


func _process(delta: float) -> void:
	if not _active:
		return

	if get_tree().get_nodes_in_group("enemy").size() >= _eff_max_enemies:
		return

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = _eff_spawn_interval
		_spawn_enemy()


func _spawn_enemy() -> void:
	if not enemy_scene:
		return

	var enemy: Node2D = enemy_scene.instantiate()
	get_parent().add_child(enemy)
	enemy.global_position = _get_spawn_position()
	# Scale enemy stats after add_child so AdvancedConfig's node_added override has run.
	# HealthComponent._ready() caches entity.max_health, so we must re-sync it after scaling.
	var ent := enemy as LivingEntity
	if ent:
		ent.max_health *= _enemy_health_mult
		ent.bullet_damage *= _enemy_damage_mult
		ent.max_speed *= _enemy_speed_mult
		if ent.healthComponent:
			ent.healthComponent.max_health = ent.max_health
			ent.healthComponent.current_health = ent.max_health


func _get_spawn_position() -> Vector2:
	var camera := get_viewport().get_camera_2d()
	var inner_margin := float(_proc_gen.cell_size) * 1.5

	if not camera:
		return Vector2(
			randf_range(inner_margin, _arena_bounds.x - inner_margin),
			randf_range(inner_margin, _arena_bounds.y - inner_margin)
		)

	var viewport_size := get_viewport().get_visible_rect().size
	var zoom := camera.zoom
	# Half-extents of the visible world area, plus a small buffer so spawns are clearly off-screen
	var half_w := (viewport_size.x / zoom.x) * 0.5 + float(_proc_gen.cell_size) * 2.0
	var half_h := (viewport_size.y / zoom.y) * 0.5 + float(_proc_gen.cell_size) * 2.0
	var cam_center := camera.get_screen_center_position()

	var pos: Vector2
	match randi() % 4:
		0:  # top
			pos = Vector2(randf_range(cam_center.x - half_w, cam_center.x + half_w), cam_center.y - half_h)
		1:  # bottom
			pos = Vector2(randf_range(cam_center.x - half_w, cam_center.x + half_w), cam_center.y + half_h)
		2:  # left
			pos = Vector2(cam_center.x - half_w, randf_range(cam_center.y - half_h, cam_center.y + half_h))
		_:  # right
			pos = Vector2(cam_center.x + half_w, randf_range(cam_center.y - half_h, cam_center.y + half_h))

	# Clamp inside arena walls
	pos.x = clamp(pos.x, inner_margin, _arena_bounds.x - inner_margin)
	pos.y = clamp(pos.y, inner_margin, _arena_bounds.y - inner_margin)

	return pos
