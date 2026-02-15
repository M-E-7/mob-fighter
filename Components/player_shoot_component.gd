extends Node
class_name PlayerShootComponent
## Component that handles shooting projectiles toward the mouse cursor

@export var entity: Entity
@export var bullet_scene: PackedScene

var shoot_timer: float = 0.0


func _physics_process(delta: float) -> void:
	if not entity:
		return

	shoot_timer = max(shoot_timer - delta, 0.0)

	if Input.is_action_pressed("shoot") and shoot_timer <= 0.0:
		shoot()
		shoot_timer = 1.0 / entity.fire_rate


func shoot() -> void:
	var bullet: Bullet = bullet_scene.instantiate()
	var mouse_pos := entity.get_global_mouse_position()
	var direction := (mouse_pos - entity.global_position).normalized()

	bullet.setup(direction, entity.bullet_damage, entity)

	entity.get_tree().current_scene.add_child(bullet)
	bullet.global_position = entity.global_position
