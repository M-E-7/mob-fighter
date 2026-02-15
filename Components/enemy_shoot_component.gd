extends Node
class_name EnemyShootComponent
## Component that shoots projectiles toward the player

@export var entity: Entity
@export var bullet_scene: PackedScene

var shoot_timer: float = 0.0
var player: Node2D


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	print(player)
	print("player in shoot enemy")

	if not entity or not player:
		return

	shoot_timer = max(shoot_timer - delta, 0.0)

	if shoot_timer <= 0.0:
		shoot()
		shoot_timer = 1.0 / entity.fire_rate


func shoot() -> void:
	var bullet: Bullet = bullet_scene.instantiate()
	var direction := (player.global_position - entity.global_position).normalized()

	bullet.setup(direction, entity.bullet_damage, entity)

	entity.get_tree().current_scene.add_child(bullet)
	bullet.global_position = entity.global_position
