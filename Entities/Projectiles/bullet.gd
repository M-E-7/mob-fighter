extends Area2D
class_name Bullet
## Projectile that travels in a direction and deals damage on contact

@export var beam_mesh: MeshInstance2D

var speed: float = 1000.0
var damage: float = 10.0
var direction: Vector2 = Vector2.ZERO
var source: Node2D

var _color: Color = Color(1.0, 0.3, 0.1)


func _ready() -> void:
	if beam_mesh and beam_mesh.material is ShaderMaterial:
		_color = (beam_mesh.material as ShaderMaterial).get_shader_parameter("beam_color")


func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func setup(dir: Vector2, dmg: float, src: Node2D, spd: float = 1000.0) -> void:
	direction = dir.normalized()
	damage = dmg
	source = src
	speed = spd
	rotation = direction.angle()


func _on_body_entered(body: Node2D) -> void:
	if body is StaticBody2D:
		_emit_impact()
		queue_free()


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
		area.take_damage(damage, source as LivingEntity)
	_emit_impact()
	queue_free()


func _same_team(target: Node) -> bool:
	if source.is_in_group("player") and target.is_in_group("player"):
		return true
	if source.is_in_group("enemy") and target.is_in_group("enemy"):
		return true
	return false


func _emit_impact() -> void:
	var src: LivingEntity = null
	if is_instance_valid(source):
		src = source as LivingEntity
	EventBus.bullet_impacted.emit(src, global_position, direction, _color)
