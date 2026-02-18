extends ShootComponent
class_name PlayerShootComponent
## Shoots projectiles toward the mouse cursor on input


func should_shoot() -> bool:
	return Input.is_action_pressed("shoot")


func get_direction() -> Vector2:
	var mouse_pos := entity.get_global_mouse_position()
	return (mouse_pos - entity.global_position).normalized()
