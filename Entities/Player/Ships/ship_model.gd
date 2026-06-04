extends Node2D
class_name ShipModel

@export_group("References")
@export var neon_component: NeonShaderComponent
@export var thruster_component: ThrusterComponent

@export_group("Collision")
@export var collision_shape: Shape2D


func setup(entity: LivingEntity) -> void:
	if neon_component:
		neon_component.entity = entity
	if thruster_component:
		thruster_component.entity = entity
