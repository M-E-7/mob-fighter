extends Node
class_name EnemyMovementComponent
## Component that moves the enemy towards the player

@export var entity: LivingEntity

var player: Node2D


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	print(player)
	print("player in movement enemy")
	if not entity or not player:
		return

	var direction := (player.global_position - entity.global_position).normalized()
	var target_velocity := direction * entity.max_speed

	entity.velocity = entity.velocity.move_toward(target_velocity, entity.acceleration * delta)
	entity.move_and_slide()
