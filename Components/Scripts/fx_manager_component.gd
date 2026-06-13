extends Node2D
class_name FXManagerComponent

@export_group("Scenes")
@export var death_fx_scene: PackedScene
@export var impact_fx_scene: PackedScene
@export var muzzle_fx_scene: PackedScene

@export_group("Toggles")
@export var death_fx_enabled: bool = true
@export var impact_fx_enabled: bool = true
@export var muzzle_flash_enabled: bool = true
@export var enemy_muzzle_flash: bool = false

@export_group("Hit Stop")
@export var hit_stop_enabled: bool = true
@export_range(0.0, 0.3, 0.01) var hit_stop_duration: float = 0.04
@export_range(0.05, 1.0, 0.05) var hit_stop_scale: float = 0.15

@export_group("Limits")
@export_range(8, 128, 1) var max_active_fx: int = 48

var _hit_stop_count: int = 0

const _FALLBACK_COLOR := Color(0.0, 1.0, 0.9)


func _ready() -> void:
	add_to_group("fx_manager")
	EventBus.entity_died.connect(_on_entity_died)
	EventBus.bullet_impacted.connect(_on_bullet_impacted)
	EventBus.entity_shot.connect(_on_entity_shot)
	EventBus.xp_orb_collected.connect(_on_xp_orb_collected)
	_prewarm.call_deferred()


func _on_entity_died(entity: LivingEntity) -> void:
	if not death_fx_enabled or not entity.is_in_group("enemy"):
		return
	if get_child_count() >= max_active_fx:
		return
	# Entity is still valid here — queue_free() only takes effect after the signal.
	var fx: EnemyDeathFX = death_fx_scene.instantiate()
	add_child(fx)
	fx.global_position = entity.global_position
	fx.play(_entity_neon_color(entity))
	_trigger_hit_stop()


func _on_bullet_impacted(_source: LivingEntity, world_position: Vector2, direction: Vector2, color: Color) -> void:
	if not impact_fx_enabled or get_child_count() >= max_active_fx:
		return
	var fx: BulletImpactFX = impact_fx_scene.instantiate()
	add_child(fx)
	fx.global_position = world_position
	# Sparks bounce back toward the shooter.
	fx.play(color, -direction)


func _on_entity_shot(entity: LivingEntity, world_position: Vector2, direction: Vector2) -> void:
	if not muzzle_flash_enabled or get_child_count() >= max_active_fx:
		return
	if not enemy_muzzle_flash and not entity.is_in_group("player"):
		return
	var fx: MuzzleFlashFX = muzzle_fx_scene.instantiate()
	add_child(fx)
	fx.global_position = world_position
	fx.play(_entity_neon_color(entity), direction)


func _on_xp_orb_collected(world_position: Vector2, _amount: float) -> void:
	if not impact_fx_enabled or get_child_count() >= max_active_fx:
		return
	var fx: BulletImpactFX = impact_fx_scene.instantiate()
	add_child(fx)
	fx.global_position = world_position
	fx.play(Color(1.0, 0.85, 0.2), Vector2.from_angle(randf() * TAU))


func _trigger_hit_stop() -> void:
	if not hit_stop_enabled or hit_stop_duration <= 0.0 or get_tree().paused:
		return
	_hit_stop_count += 1
	Engine.time_scale = hit_stop_scale
	# ignore_time_scale, or the restore timer would be slowed by its own effect.
	var timer := get_tree().create_timer(hit_stop_duration, true, false, true)
	timer.timeout.connect(_on_hit_stop_timeout)


func _on_hit_stop_timeout() -> void:
	_hit_stop_count = maxi(0, _hit_stop_count - 1)
	if _hit_stop_count == 0:
		Engine.time_scale = 1.0


func _entity_neon_color(entity: LivingEntity) -> Color:
	var neon := _find_neon(entity)
	return neon.neon_color if neon else _FALLBACK_COLOR


func _find_neon(node: Node) -> NeonShaderComponent:
	for child in node.get_children():
		if child is NeonShaderComponent:
			return child
		var nested := _find_neon(child)
		if nested:
			return nested
	return null


# Plays each effect once near the player so particle/shader pipelines compile
# before the first real kill instead of hitching mid-fight.
func _prewarm() -> void:
	var anchor := get_tree().get_first_node_in_group("player") as Node2D
	var pos := anchor.global_position if anchor else Vector2.ZERO
	for scene: PackedScene in [death_fx_scene, impact_fx_scene, muzzle_fx_scene]:
		if not scene:
			continue
		var fx: Node2D = scene.instantiate()
		fx.modulate = Color(1, 1, 1, 0.02)
		add_child(fx)
		fx.global_position = pos
		if fx is EnemyDeathFX:
			fx.play(_FALLBACK_COLOR)
		else:
			fx.play(_FALLBACK_COLOR, Vector2.RIGHT)
