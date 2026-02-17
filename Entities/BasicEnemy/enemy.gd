extends LivingEntity
## Enemy entity that chases and shoots at the player


func _ready() -> void:
	add_to_group("enemy")
	EventBus.entity_died.connect(_on_entity_died)
	EventBus.entity_damaged.connect(_on_entity_damaged)
