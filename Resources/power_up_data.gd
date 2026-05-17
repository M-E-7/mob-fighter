extends Resource
class_name PowerUpData

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
## Key matching an @export property on LivingEntity (e.g. "max_speed", "fire_rate")
@export var stat_key: String = ""
## Additive bonus fraction per stack: 0.15 = +15% of base stat
@export var bonus_percent: float = 0.1
