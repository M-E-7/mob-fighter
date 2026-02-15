extends Node
## Global event bus for decoupled communication between systems

# Entity lifecycle
signal entity_died(entity: Node)

# Damage
signal entity_damaged(entity: Node, amount: float)

# Health
signal health_changed(entity: Node, current_health: float, max_health: float)
