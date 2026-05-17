extends Node
class_name XPDropComponent

@export_group("References")
@export var entity: LivingEntity
@export var orb_scene: PackedScene

@export_group("Settings")
@export var xp_amount: float = 1.0


func _ready() -> void:
	EventBus.entity_died.connect(_on_entity_died)


func _on_entity_died(dead_entity: LivingEntity) -> void:
	if dead_entity != entity:
		return
	var orb: ExperienceOrb = orb_scene.instantiate()
	orb.xp_value = xp_amount
	var spawn_pos := entity.global_position
	entity.get_parent().add_child.call_deferred(orb)
	orb.set_deferred("global_position", spawn_pos)
