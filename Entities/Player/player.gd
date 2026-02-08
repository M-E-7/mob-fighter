extends CharacterBody2D
class_name Player
## Player coordinator that manages components
## Provides clean API for external systems to access player components

@onready var movement: MovementComponent = $MovementComponent
@onready var facing: FacingComponent = $FacingComponent


func _ready() -> void:
	print("Player _ready() called")
	print("Movement component exists: ", movement != null)
	print("Facing component exists: ", facing != null)


## Get the movement component
func get_movement_component() -> MovementComponent:
	return movement


## Get the facing component
func get_facing_component() -> FacingComponent:
	return facing
