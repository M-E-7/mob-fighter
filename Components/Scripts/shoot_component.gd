extends Node
class_name ShootComponent

@export var entity: LivingEntity
@export var bullet_scene: PackedScene

var shoot_timer: float = 0.0


func try_shoot(shoot_pressed: bool, direction: Vector2, delta: float) -> void:
	if not entity:
		return

	shoot_timer = max(shoot_timer - delta, 0.0)

	if shoot_pressed and shoot_timer <= 0.0:
		shoot(direction)
		shoot_timer = 1.0 / entity.fire_rate


func shoot(direction: Vector2) -> void:
	var bullet: Bullet = bullet_scene.instantiate()

	bullet.setup(direction, entity.bullet_damage, entity, entity.bullet_speed)

	entity.get_tree().current_scene.add_child(bullet)
	bullet.global_position = entity.global_position
