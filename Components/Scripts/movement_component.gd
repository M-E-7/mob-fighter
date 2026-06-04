extends Node
class_name MovementComponent

@export var entity: LivingEntity


func move(direction: Vector2, turbo: bool, delta: float) -> void:
	if not entity:
		return

	var facing := Vector2.from_angle(entity.rotation - PI / 2.0)
	var right := facing.rotated(PI / 2.0)
	var world_dir := facing * (-direction.y) + right * direction.x

	if turbo:
		world_dir += facing

	var speed := entity.max_speed * (entity.turbo_speed_multiplier if turbo else 1.0)

	if world_dir.length() > 0:
		var target_velocity := world_dir.normalized() * speed
		entity.velocity = entity.velocity.move_toward(target_velocity, entity.acceleration * delta)
	else:
		entity.velocity = entity.velocity.move_toward(Vector2.ZERO, entity.friction * delta)

	entity.move_and_slide()
