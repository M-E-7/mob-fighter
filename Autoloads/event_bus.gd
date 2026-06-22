extends Node
## Global event bus for decoupled communication between systems

# Entity lifecycle
signal entity_died(entity: LivingEntity)

# Damage
signal entity_damaged(entity: LivingEntity, amount: float)

# Combat FX
signal entity_shot(entity: LivingEntity, world_position: Vector2, direction: Vector2)
signal bullet_impacted(source: LivingEntity, world_position: Vector2, direction: Vector2, color: Color)

# Health
signal health_changed(entity: LivingEntity, current_health: float, max_health: float)

# Progression
signal xp_collected(amount: float)
signal xp_orb_collected(world_position: Vector2, amount: float)
signal currency_changed(total: int)
signal power_up_applied(player: LivingEntity, power_up: PowerUpData)

# Music
signal beat_detected()

# Roguelike run loop
signal objective_progress_changed(current: int, target: int)
signal sector_objective_completed()
signal exit_port_spawned(port: ExitPort)
signal exit_port_entered()
signal boss_spawned(boss: LivingEntity, display_name: String, max_health: float)
