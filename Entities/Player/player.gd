extends LivingEntity
class_name Player

func _ready() -> void:
	add_to_group("player")
	EventBus.entity_died.connect(_on_entity_died)
	EventBus.entity_damaged.connect(_on_entity_damaged)
	if healthDisplayComponent:
		healthDisplayComponent.call_deferred("hide_bars")
	var ship := get_node_or_null("PlayerShip") as ShipModel
	if ship:
		ship.setup(self)
		if ship.collision_shape:
			$CollisionShape2D.shape = ship.collision_shape




