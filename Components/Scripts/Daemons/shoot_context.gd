extends RefCounted
class_name ShootContext
## Mutable payload passed to Daemon.on_shoot(); daemons append/modify the shots that actually fire.

var aim_direction: Vector2
var base_damage: float
var base_speed: float
var color: Color
## Each entry: {"direction": Vector2, "damage": float, "speed": float, "tags": Array}
var shots: Array[Dictionary] = []


func add_shot(dir: Vector2, dmg: float, spd: float, tags: Array = []) -> void:
	shots.append({"direction": dir, "damage": dmg, "speed": spd, "tags": tags})
