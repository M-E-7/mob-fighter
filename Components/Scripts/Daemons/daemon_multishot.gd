extends Daemon
class_name DaemonMultishot
## on_shoot: fans extra projectiles around the aim direction. Total extras = extra_shots * stacks.

@export_group("Multishot")
@export var extra_shots: int = 1       ## extra projectiles added per owned stack
@export var spread_deg: float = 12.0   ## degrees between adjacent fanned shots


func on_shoot(ctx: ShootContext) -> void:
	var extra := extra_shots * stacks
	if extra <= 0:
		return
	var spread := deg_to_rad(spread_deg)
	for i in extra:
		# Alternate sides outward: +1, -1, +2, -2, ...
		var step := (i / 2) + 1
		var side := 1.0 if i % 2 == 0 else -1.0
		var dir := ctx.aim_direction.rotated(side * float(step) * spread)
		ctx.add_shot(dir, ctx.base_damage, ctx.base_speed)
