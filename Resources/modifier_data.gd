extends Resource
class_name ModifierData

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
## Base Bits cost before escalation; escalation applied at runtime by RunState.modifier_cost()
@export var cost: int = 20
## Behavior implementing the hook methods (a Daemon subclass script)
@export var behavior_script: GDScript
## 1 = unique (one per run); >1 = stack up to N; 0 = unlimited stacks
@export var max_stacks: int = 1
## Per-Daemon tunables read by the behavior (e.g. {"extra_shots": 1})
@export var params: Dictionary = {}


func is_stackable() -> bool:
	return max_stacks != 1
