extends Daemon
class_name DaemonSplit
## on_hit: a bullet spawns child bullets at the impact point. Children are meta-tagged so they
## never re-split — without the guard, split-spawned bullets would split again forever.
## Insertion is deferred: on_hit runs inside Bullet._on_area_entered (a physics callback), and
## adding collision objects mid-physics-flush is forbidden.

@export_group("Split")
@export var split_count: int = 2           ## child bullets spawned on impact
@export var spread_deg: float = 30.0       ## fan angle of the children
@export var child_damage_mult: float = 0.6 ## child damage as a fraction of the parent's

const _BULLET := preload("res://Entities/Projectiles/bullet.tscn")


func on_hit(ctx: HitContext) -> void:
	var bullet := ctx.bullet
	if not is_instance_valid(bullet):
		return
	if bullet.get_meta("daemon_split_child", false):
		return
	var parent := bullet.get_parent()
	if not parent:
		return
	var spread := deg_to_rad(spread_deg)
	var dmg: float = bullet.damage * child_damage_mult
	var spd: float = bullet.speed
	var pos := bullet.global_position
	var base_dir := bullet.direction
	var color := Color(1, 1, 1, 1)
	if bullet.source is LivingEntity:
		color = (bullet.source as LivingEntity).bullet_color
	for i in split_count:
		var offset := (float(i) - float(split_count - 1) / 2.0) * spread
		var child: Bullet = _BULLET.instantiate()
		child.set_meta("daemon_split_child", true)
		child.setup(base_dir.rotated(offset), dmg, bullet.source, spd)
		_spawn_child.call_deferred(parent, child, pos, color)


func _spawn_child(parent: Node, child: Bullet, pos: Vector2, color: Color) -> void:
	if not is_instance_valid(parent):
		child.free()
		return
	parent.add_child(child)
	child.global_position = pos
	child.set_color(color)
