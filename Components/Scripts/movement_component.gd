extends Node
class_name MovementComponent

@export var entity: LivingEntity


func move(direction: Vector2, delta: float) -> void:
	if not entity:
		return

	if direction.length() > 0:
		var target_velocity := direction * entity.max_speed
		entity.velocity = entity.velocity.move_toward(target_velocity, entity.acceleration * delta)
	else:
		entity.velocity = entity.velocity.move_toward(Vector2.ZERO, entity.friction * delta)

	entity.move_and_slide()
