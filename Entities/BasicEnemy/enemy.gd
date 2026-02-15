extends Entity
## Enemy entity that chases and shoots at the player


func _ready() -> void:
	add_to_group("enemy")
	if healthComponent:
		healthComponent.died.connect(queue_free)
	if hurtboxComponent:
		hurtboxComponent.damaged.connect(take_damage)
