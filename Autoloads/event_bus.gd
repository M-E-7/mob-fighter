extends Node
## Global event bus for decoupled communication between systems

# Entity lifecycle
signal entity_died(entity: LivingEntity)

# Damage
signal entity_damaged(entity: LivingEntity, amount: float)

# Health
signal health_changed(entity: LivingEntity, current_health: float, max_health: float)

# Progression
signal xp_collected(amount: float)
signal xp_orb_collected(world_position: Vector2, amount: float)
signal player_leveled_up(player: LivingEntity)
signal xp_updated(player: LivingEntity, current_xp: float, required_xp: float, current_level: int)
signal power_up_applied(player: LivingEntity, power_up: PowerUpData)

# Music
signal beat_detected()
