extends Area2D
class_name Bullet
## Projectile that travels in a direction and deals damage on contact

var speed: float = 500.0
var damage: float = 10.0
var direction: Vector2 = Vector2.ZERO


func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func setup(dir: Vector2, dmg: float, spd: float = 500.0) -> void:
	direction = dir.normalized()
	damage = dmg
	speed = spd
	rotation = direction.angle()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
