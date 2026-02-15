extends Area2D
class_name HurtboxComponent
## Component that detects incoming damage and signals up to the entity

signal damaged(amount: float)


func take_damage(amount: float) -> void:
	damaged.emit(amount)
