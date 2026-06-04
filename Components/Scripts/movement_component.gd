extends Node
class_name MovementComponent

@export var entity: LivingEntity


func move(direction: Vector2, thrust: bool, delta: float) -> void:
	if not entity:
		return

	var effective_direction := direction
	if thrust:
		effective_direction += Vector2.from_angle(entity.rotation - PI / 2.0)

	if effective_direction.length() > 0:
		var target_velocity := effective_direction.normalized() * entity.max_speed
		entity.velocity = entity.velocity.move_toward(target_velocity, entity.acceleration * delta)
	else:
		entity.velocity = entity.velocity.move_toward(Vector2.ZERO, entity.friction * delta)

	entity.move_and_slide()
