extends InputComponent
class_name EnemyInputComponent

@export var entity: LivingEntity

var player: Node2D


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")


func _process(_delta: float) -> void:
	if not entity or not player:
		return

	var direction := (player.global_position - entity.global_position).normalized()
	move_vector = direction
	shoot_pressed = true
	aim_direction = direction
