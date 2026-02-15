extends Area2D
class_name Bullet
## Projectile that travels in a direction and deals damage on contact

var speed: float = 500.0
var damage: float = 10.0
var direction: Vector2 = Vector2.ZERO
var source: Node2D


func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func setup(dir: Vector2, dmg: float, src: Node2D, spd: float = 500.0) -> void:
	direction = dir.normalized()
	damage = dmg
	source = src
	speed = spd
	rotation = direction.angle()


func _on_area_entered(area: Area2D) -> void:
	if area is HurtboxComponent:
		if not is_instance_valid(source):
			queue_free()
			return
		var target := area.owner
		if target == source:
			return
		if _same_team(target):
			return
		area.take_damage(damage)
	queue_free()


func _same_team(target: Node) -> bool:
	if source.is_in_group("player") and target.is_in_group("player"):
		return true
	if source.is_in_group("enemy") and target.is_in_group("enemy"):
		return true
	return false
