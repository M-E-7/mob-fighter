extends LivingEntity

func _ready() -> void:
	add_to_group("player")
	EventBus.entity_died.connect(_on_entity_died)
	EventBus.entity_damaged.connect(_on_entity_damaged)

## Enemy entity that chases and shoots at the player



