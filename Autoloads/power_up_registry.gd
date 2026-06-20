extends Node

var power_ups: Array[PowerUpData] = []


func _ready() -> void:
	power_ups = [
		_make("move_speed",    "Defrag",        "Move +15% faster",            "max_speed",     0.15, 10),
		_make("fire_rate",     "Overclock",     "Fire rate +20%",              "fire_rate",     0.20, 12),
		_make("bullet_damage", "Heap Smash",    "Damage +25%",                 "bullet_damage", 0.25, 15),
		_make("max_health",    "Firewall",      "+20% max integrity",          "max_health",    0.20, 12),
		_make("bullet_speed",  "Packet Burst",  "Bullet speed +20%",           "bullet_speed",  0.20,  8),
	]


func _make(id: String, display_name: String, description: String, stat_key: String, bonus: float, cost: int) -> PowerUpData:
	var d := PowerUpData.new()
	d.id = id
	d.display_name = display_name
	d.description = description
	d.stat_key = stat_key
	d.bonus_percent = bonus
	d.cost = cost
	return d
