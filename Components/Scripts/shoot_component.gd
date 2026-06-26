extends Node
class_name ShootComponent

@export var entity: LivingEntity
@export var bullet_scene: PackedScene
@export var muzzle_offset: float = 20.0

var shoot_timer: float = 0.0

var _host: DaemonHostComponent


func _ready() -> void:
	if entity:
		_host = entity.get_node_or_null("DaemonHostComponent") as DaemonHostComponent


func try_shoot(shoot_pressed: bool, direction: Vector2, delta: float) -> void:
	if not entity:
		return

	shoot_timer = max(shoot_timer - delta, 0.0)

	if shoot_pressed and shoot_timer <= 0.0:
		shoot(direction)
		shoot_timer = 1.0 / entity.fire_rate


func shoot(direction: Vector2) -> void:
	var ctx := ShootContext.new()
	ctx.aim_direction = direction
	ctx.base_damage = entity.bullet_damage
	ctx.base_speed = entity.bullet_speed
	ctx.color = entity.bullet_color
	ctx.add_shot(direction, entity.bullet_damage, entity.bullet_speed)

	if _host:
		_host.dispatch_shoot(ctx)

	for shot: Dictionary in ctx.shots:
		_spawn_bullet(shot)


func _spawn_bullet(shot: Dictionary) -> void:
	var dir: Vector2 = shot["direction"]
	var bullet: Bullet = bullet_scene.instantiate()
	bullet.setup(dir, shot["damage"], entity, shot["speed"])
	var spawn_pos := entity.global_position + dir * muzzle_offset
	entity.get_parent().add_child(bullet)
	bullet.global_position = spawn_pos
	bullet.set_color(entity.bullet_color)
	for tag: StringName in shot.get("tags", []):
		bullet.set_meta(tag, true)
	EventBus.entity_shot.emit(entity, spawn_pos, dir)
