extends ShootComponent
class_name EnemyShootComponent
## Shoots projectiles toward the player automatically

var player: Node2D


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")


func should_shoot() -> bool:
	return player != null


func get_direction() -> Vector2:
	return (player.global_position - entity.global_position).normalized()
