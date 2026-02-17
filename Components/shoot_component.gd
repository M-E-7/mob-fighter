extends Node
class_name ShootComponent
## Base shooting component - override get_direction() and should_shoot() in subclasses

@export var entity: LivingEntity
@export var bullet_scene: PackedScene

var shoot_timer: float = 0.0


func _physics_process(delta: float) -> void:
	if not entity:
		return

	shoot_timer = max(shoot_timer - delta, 0.0)

	if should_shoot() and shoot_timer <= 0.0:
		shoot()
		shoot_timer = 1.0 / entity.fire_rate


func should_shoot() -> bool:
	return false


func get_direction() -> Vector2:
	return Vector2.RIGHT


func shoot() -> void:
	var bullet: Bullet = bullet_scene.instantiate()
	var direction := get_direction()

	bullet.setup(direction, entity.bullet_damage, entity)

	entity.get_tree().current_scene.add_child(bullet)
	bullet.global_position = entity.global_position
