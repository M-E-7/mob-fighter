extends Area2D
class_name HurtboxComponent
## Component that detects incoming damage and signals up to the entity


func take_damage(amount: float) -> void:
	EventBus.entity_damaged.emit(owner, amount)
