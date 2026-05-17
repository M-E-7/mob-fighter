extends CharacterBody2D
class_name LivingEntity

@export_group("Components")
@export var inputComponent: InputComponent
@export var movementComponent: MovementComponent
@export var shootComponent: ShootComponent
@export var hurtboxComponent: HurtboxComponent
@export var healthComponent: HealthComponent
@export var healthDisplayComponent: HealthDisplayComponent

@export_group("Movement Settings")
@export var max_speed: float = 200.0
@export var acceleration: float = 1000.0
@export var friction: float = 800.0

@export_group("Health Settings")
@export var max_health: float = 100.0
@export var starting_health: float = 100.0

@export_group("Shooting Settings")
@export var fire_rate: float = 5.0
@export var bullet_damage: float = 10.0
@export var bullet_speed: float = 500.0


func _ready() -> void:
	pass


func _physics_process(delta: float) -> void:
	if not inputComponent:
		return

	if movementComponent:
		movementComponent.move(inputComponent.move_vector, delta)

	if shootComponent:
		shootComponent.try_shoot(inputComponent.shoot_pressed, inputComponent.aim_direction, delta)


func _on_entity_died(entity: Node) -> void:
	if entity == self:
		queue_free()


func _on_entity_damaged(entity: Node, amount: float) -> void:
	if entity == self and healthComponent:
		healthComponent.take_damage(amount)
