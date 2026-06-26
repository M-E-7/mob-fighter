extends Node
## Central pool of all Daemons (modifiers). Mirrors PowerUpRegistry.
## No class_name — the autoload name IS the global identifier.

var modifiers: Array[ModifierData] = []


func _ready() -> void:
	# Gameplay tunables (extra_shots, spread, split_count, stat mults, ...) live as @export vars on
	# the behavior scripts — edit them there. `params` here is an optional per-entry override.
	modifiers = [
		_make("multishot", "Fork Process", "Fire extra projectiles in a spread",
			preload("res://Components/Scripts/Daemons/daemon_multishot.gd"), 25, 3),
		_make("split", "Recursion Bomb", "Bullets split into shards on impact",
			preload("res://Components/Scripts/Daemons/daemon_split.gd"), 30, 1),
		_make("armor", "Hardened Kernel", "Slower, but +50% integrity",
			preload("res://Components/Scripts/Daemons/daemon_armor.gd"), 28, 1),
	]


func find(id: String) -> ModifierData:
	for m: ModifierData in modifiers:
		if m.id == id:
			return m
	return null


func _make(id: String, display_name: String, description: String, behavior: GDScript,
		cost: int, max_stacks: int, params: Dictionary = {}) -> ModifierData:
	var d := ModifierData.new()
	d.id = id
	d.display_name = display_name
	d.description = description
	d.behavior_script = behavior
	d.cost = cost
	d.max_stacks = max_stacks
	d.params = params
	return d
