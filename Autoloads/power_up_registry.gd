extends Node

var power_ups: Array[PowerUpData] = []


func _ready() -> void:
	power_ups = [
		_make("move_speed",    "Swift Boots",      "Move +15% faster",             "max_speed",    0.15),
		_make("fire_rate",     "Rapid Fire",        "Shoot +20% faster",            "fire_rate",    0.20),
		_make("bullet_damage", "Heavy Rounds",      "Deal +25% more damage",        "bullet_damage",0.25),
		_make("max_health",    "Iron Will",         "Gain +20% max health",         "max_health",   0.20),
		_make("bullet_speed",  "Velocity Rounds",   "Bullets travel +20% faster",   "bullet_speed", 0.20),
	]


func _make(id: String, display_name: String, description: String, stat_key: String, bonus: float) -> PowerUpData:
	var d := PowerUpData.new()
	d.id = id
	d.display_name = display_name
	d.description = description
	d.stat_key = stat_key
	d.bonus_percent = bonus
	return d
