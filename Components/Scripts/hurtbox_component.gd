extends Area2D
class_name HurtboxComponent
## Component that detects incoming damage and signals up to the entity


func take_damage(amount: float, attacker: LivingEntity = null) -> void:
	if attacker:
		(owner as LivingEntity).last_attacker = attacker
	EventBus.entity_damaged.emit(owner, amount)
