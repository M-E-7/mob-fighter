extends Node

# Combat prop names shared between Player and Enemy
const _COMBAT_PROPS := ["fire_rate", "bullet_damage", "bullet_speed", "max_health"]

const PROPERTY_DEFS: Array[Dictionary] = [
	# ── Player Movement ─────────────────────────────────────────────────────────
	{"group": "Player Movement", "class": "Player", "name": "max_speed",
		"type": TYPE_FLOAT, "default": 400.0, "min": 50.0, "max": 2000.0, "step": 10.0},
	{"group": "Player Movement", "class": "Player", "name": "acceleration",
		"type": TYPE_FLOAT, "default": 800.0, "min": 50.0, "max": 3000.0, "step": 10.0},
	{"group": "Player Movement", "class": "Player", "name": "friction",
		"type": TYPE_FLOAT, "default": 100.0, "min": 0.0, "max": 1000.0, "step": 5.0},
	{"group": "Player Movement", "class": "Player", "name": "turbo_speed_multiplier",
		"type": TYPE_FLOAT, "default": 1.8, "min": 1.0, "max": 5.0, "step": 0.05},

	# ── Player Input ─────────────────────────────────────────────────────────────
	{"group": "Player Input", "class": "PlayerInputComponent", "name": "turn_speed",
		"type": TYPE_FLOAT, "default": 8.0, "min": 0.5, "max": 30.0, "step": 0.1},

	# ── Combat (applies to Player, Player2, and Enemy) ───────────────────────────
	{"group": "Combat", "class": "Player", "name": "fire_rate",
		"type": TYPE_FLOAT, "default": 5.0, "min": 0.1, "max": 30.0, "step": 0.1},
	{"group": "Combat", "class": "Player", "name": "bullet_damage",
		"type": TYPE_FLOAT, "default": 10.0, "min": 1.0, "max": 500.0, "step": 1.0},
	{"group": "Combat", "class": "Player", "name": "bullet_speed",
		"type": TYPE_FLOAT, "default": 1000.0, "min": 100.0, "max": 3000.0, "step": 10.0},
	{"group": "Combat", "class": "Player", "name": "max_health",
		"type": TYPE_FLOAT, "default": 100.0, "min": 10.0, "max": 10000.0, "step": 10.0},

	# ── Enemy Spawning ───────────────────────────────────────────────────────────
	{"group": "Enemy Spawning", "class": "EnemySpawnerComponent", "name": "spawn_interval",
		"type": TYPE_FLOAT, "default": 2.0, "min": 0.1, "max": 30.0, "step": 0.1},
	{"group": "Enemy Spawning", "class": "EnemySpawnerComponent", "name": "max_enemies",
		"type": TYPE_INT, "default": 20, "min": 1, "max": 200, "step": 1},

	# ── Level Generation ─────────────────────────────────────────────────────────
	{"group": "Level Generation", "class": "ProcGenLevelComponent", "name": "arena_width",
		"type": TYPE_INT, "default": 40, "min": 10, "max": 100, "step": 1},
	{"group": "Level Generation", "class": "ProcGenLevelComponent", "name": "arena_height",
		"type": TYPE_INT, "default": 30, "min": 10, "max": 100, "step": 1},
	{"group": "Level Generation", "class": "ProcGenLevelComponent", "name": "cell_size",
		"type": TYPE_INT, "default": 32, "min": 16, "max": 128, "step": 8},
	{"group": "Level Generation", "class": "ProcGenLevelComponent", "name": "obstacle_density",
		"type": TYPE_FLOAT, "default": 0.3, "min": 0.0, "max": 1.0, "step": 0.01},
	{"group": "Level Generation", "class": "ProcGenLevelComponent", "name": "clear_radius",
		"type": TYPE_FLOAT, "default": 4.0, "min": 1.0, "max": 20.0, "step": 0.5},
	{"group": "Level Generation", "class": "ProcGenLevelComponent", "name": "noise_frequency",
		"type": TYPE_FLOAT, "default": 0.1, "min": 0.01, "max": 1.0, "step": 0.01},
	{"group": "Level Generation", "class": "ProcGenLevelComponent", "name": "randomize_seed",
		"type": TYPE_BOOL, "default": true},
	{"group": "Level Generation", "class": "ProcGenLevelComponent", "name": "gen_seed",
		"type": TYPE_INT, "default": 0, "min": 0, "max": 99999, "step": 1},

	# ── Controller Input ─────────────────────────────────────────────────────────
	{"group": "Controller Input", "class": "ControllerInputComponent", "name": "move_dead_zone",
		"type": TYPE_FLOAT, "default": 0.2, "min": 0.0, "max": 0.9, "step": 0.01},
	{"group": "Controller Input", "class": "ControllerInputComponent", "name": "aim_dead_zone",
		"type": TYPE_FLOAT, "default": 0.2, "min": 0.0, "max": 0.9, "step": 0.01},
	{"group": "Controller Input", "class": "ControllerInputComponent", "name": "auto_aim_enabled",
		"type": TYPE_BOOL, "default": true},
	{"group": "Controller Input", "class": "ControllerInputComponent", "name": "auto_aim_radius",
		"type": TYPE_FLOAT, "default": 200.0, "min": 0.0, "max": 800.0, "step": 10.0},
	{"group": "Controller Input", "class": "ControllerInputComponent", "name": "auto_aim_half_angle_deg",
		"type": TYPE_FLOAT, "default": 30.0, "min": 5.0, "max": 90.0, "step": 5.0},

	# ── XP & Progression ─────────────────────────────────────────────────────────
	{"group": "XP & Progression", "class": "XPComponent", "name": "base_xp_required",
		"type": TYPE_FLOAT, "default": 10.0, "min": 1.0, "max": 200.0, "step": 1.0},
	{"group": "XP & Progression", "class": "XPComponent", "name": "track_xp",
		"type": TYPE_BOOL, "default": true},
	{"group": "XP & Progression", "class": "XPDropComponent", "name": "xp_amount",
		"type": TYPE_FLOAT, "default": 1.0, "min": 0.1, "max": 50.0, "step": 0.1},

	# ── Experience Orbs ───────────────────────────────────────────────────────────
	{"group": "Experience Orbs", "class": "ExperienceOrb", "name": "pickup_radius",
		"type": TYPE_FLOAT, "default": 80.0, "min": 0.0, "max": 500.0, "step": 5.0},
	{"group": "Experience Orbs", "class": "ExperienceOrb", "name": "attract_speed",
		"type": TYPE_FLOAT, "default": 200.0, "min": 10.0, "max": 1000.0, "step": 10.0},
	{"group": "Experience Orbs", "class": "ExperienceOrb", "name": "lifetime",
		"type": TYPE_FLOAT, "default": 8.0, "min": 1.0, "max": 60.0, "step": 0.5},

	# ── Neon Visuals ──────────────────────────────────────────────────────────────
	{"group": "Neon Visuals", "class": "NeonShaderComponent", "name": "neon_color",
		"type": TYPE_COLOR, "default": Color(1.0, 0.0, 0.2, 1.0)},
	{"group": "Neon Visuals", "class": "NeonShaderComponent", "name": "glow_intensity",
		"type": TYPE_FLOAT, "default": 2.5, "min": 0.0, "max": 20.0, "step": 0.1},
	{"group": "Neon Visuals", "class": "NeonShaderComponent", "name": "outline_width",
		"type": TYPE_FLOAT, "default": 0.06, "min": 0.0, "max": 0.5, "step": 0.01},
	{"group": "Neon Visuals", "class": "NeonShaderComponent", "name": "glow_feather",
		"type": TYPE_FLOAT, "default": 0.15, "min": 0.0, "max": 1.0, "step": 0.01},
	{"group": "Neon Visuals", "class": "NeonShaderComponent", "name": "pulse_speed",
		"type": TYPE_FLOAT, "default": 2.0, "min": 0.0, "max": 20.0, "step": 0.1},
	{"group": "Neon Visuals", "class": "NeonShaderComponent", "name": "pulse_amount",
		"type": TYPE_FLOAT, "default": 0.4, "min": 0.0, "max": 2.0, "step": 0.01},

	# ── Music Reactivity ──────────────────────────────────────────────────────────
	{"group": "Music Reactivity", "class": "MusicVisualsComponent", "name": "intensity_scale",
		"type": TYPE_FLOAT, "default": 1.0, "min": 0.0, "max": 5.0, "step": 0.05},
	{"group": "Music Reactivity", "class": "MusicVisualsComponent", "name": "bass_glow_add",
		"type": TYPE_FLOAT, "default": 4.0, "min": 0.0, "max": 20.0, "step": 0.1},
	{"group": "Music Reactivity", "class": "MusicVisualsComponent", "name": "mid_pulse_add",
		"type": TYPE_FLOAT, "default": 8.0, "min": 0.0, "max": 20.0, "step": 0.1},
	{"group": "Music Reactivity", "class": "MusicVisualsComponent", "name": "treble_feather_add",
		"type": TYPE_FLOAT, "default": 0.25, "min": 0.0, "max": 2.0, "step": 0.01},
	{"group": "Music Reactivity", "class": "MusicVisualsComponent", "name": "max_pulse_amount",
		"type": TYPE_FLOAT, "default": 0.8, "min": 0.0, "max": 2.0, "step": 0.01},
	{"group": "Music Reactivity", "class": "MusicVisualsComponent", "name": "beat_spike_strength",
		"type": TYPE_FLOAT, "default": 3.0, "min": 0.0, "max": 20.0, "step": 0.1},
	{"group": "Music Reactivity", "class": "MusicVisualsComponent", "name": "beat_spike_decay",
		"type": TYPE_FLOAT, "default": 0.25, "min": 0.0, "max": 2.0, "step": 0.01},

	# ── Thruster FX ───────────────────────────────────────────────────────────────
	{"group": "Thruster FX", "class": "ThrusterComponent", "name": "base_brightness",
		"type": TYPE_FLOAT, "default": 1.0, "min": 0.0, "max": 5.0, "step": 0.05},
	{"group": "Thruster FX", "class": "ThrusterComponent", "name": "music_bass_add",
		"type": TYPE_FLOAT, "default": 0.6, "min": 0.0, "max": 5.0, "step": 0.05},
	{"group": "Thruster FX", "class": "ThrusterComponent", "name": "beat_spike_strength",
		"type": TYPE_FLOAT, "default": 1.2, "min": 0.0, "max": 10.0, "step": 0.1},
	{"group": "Thruster FX", "class": "ThrusterComponent", "name": "beat_spike_decay",
		"type": TYPE_FLOAT, "default": 0.15, "min": 0.0, "max": 2.0, "step": 0.01},
	{"group": "Thruster FX", "class": "ThrusterComponent", "name": "turbo_brightness_add",
		"type": TYPE_FLOAT, "default": 1.5, "min": 0.0, "max": 10.0, "step": 0.1},
	{"group": "Thruster FX", "class": "ThrusterComponent", "name": "turbo_scale_mult",
		"type": TYPE_FLOAT, "default": 1.4, "min": 0.5, "max": 5.0, "step": 0.05},

	# ── Thruster Sockets (all sockets get the same override) ─────────────────────
	{"group": "Thruster Sockets", "class": "ThrusterSocket", "name": "beam_color",
		"type": TYPE_COLOR, "default": Color(0.0, 0.625, 0.5, 1.0)},
	{"group": "Thruster Sockets", "class": "ThrusterSocket", "name": "beam_length",
		"type": TYPE_FLOAT, "default": 24.0, "min": 5.0, "max": 100.0, "step": 1.0},
	{"group": "Thruster Sockets", "class": "ThrusterSocket", "name": "beam_width",
		"type": TYPE_FLOAT, "default": 8.0, "min": 1.0, "max": 40.0, "step": 0.5},
	{"group": "Thruster Sockets", "class": "ThrusterSocket", "name": "shimmer_strength",
		"type": TYPE_FLOAT, "default": 0.25, "min": 0.0, "max": 1.0, "step": 0.01},
	{"group": "Thruster Sockets", "class": "ThrusterSocket", "name": "shimmer_speed",
		"type": TYPE_FLOAT, "default": 8.0, "min": 0.1, "max": 50.0, "step": 0.1},
	{"group": "Thruster Sockets", "class": "ThrusterSocket", "name": "trail_duration",
		"type": TYPE_FLOAT, "default": 0.4, "min": 0.0, "max": 5.0, "step": 0.05},
	{"group": "Thruster Sockets", "class": "ThrusterSocket", "name": "trail_radius",
		"type": TYPE_FLOAT, "default": 3.0, "min": 0.0, "max": 20.0, "step": 0.5},
	{"group": "Thruster Sockets", "class": "ThrusterSocket", "name": "transition_time",
		"type": TYPE_FLOAT, "default": 0.12, "min": 0.01, "max": 1.0, "step": 0.01},

	# ── Audio Analysis (MusicManager autoload — applied immediately) ──────────────
	{"group": "Audio Analysis", "class": "MusicManager", "name": "smoothing",
		"type": TYPE_FLOAT, "default": 0.2, "min": 0.0, "max": 0.99, "step": 0.01},
	{"group": "Audio Analysis", "class": "MusicManager", "name": "onset_threshold",
		"type": TYPE_FLOAT, "default": 0.15, "min": 0.01, "max": 2.0, "step": 0.01},
	{"group": "Audio Analysis", "class": "MusicManager", "name": "beat_cooldown",
		"type": TYPE_FLOAT, "default": 0.0, "min": 0.0, "max": 2.0, "step": 0.05},
]

var _overrides: Dictionary = {}
# Actual inspector values read from .tscn files at startup (and refreshed from live nodes).
var _base_values: Dictionary = {}

# Scenes instantiated temporarily at startup to extract real inspector-configured defaults.
# Component scenes first, then entity scenes so per-instance values overwrite template values.
const _SEED_SCENES: Array[String] = [
	"res://Components/PlayerInputComponent.tscn",
	"res://Components/ControllerInputComponent.tscn",
	"res://Components/MovementComponent.tscn",
	"res://Components/XPComponent.tscn",
	"res://Components/XPDropComponent.tscn",
	"res://Components/MusicVisualsComponent.tscn",
	"res://Components/NeonShaderComponent.tscn",
	"res://Components/ThrusterComponent.tscn",
	"res://Components/ThrusterSocket.tscn",
	"res://Components/EnemySpawnerComponent.tscn",
	"res://Components/ProcGenLevelComponent.tscn",
	"res://Entities/Player/Ships/PlayerShip.tscn",
	"res://Entities/Player/player.tscn",
	"res://Entities/BasicEnemy/enemy.tscn",
	"res://Entities/ExperienceOrb/experience_orb.tscn",
]


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	_capture_node_props(MusicManager, "MusicManager")
	_preload_scene_defaults()


func _preload_scene_defaults() -> void:
	for path: String in _SEED_SCENES:
		var packed := load(path) as PackedScene
		if not packed:
			continue
		var inst := packed.instantiate()
		_scan_for_base_values(inst)
		inst.free()


func _scan_for_base_values(node: Node) -> void:
	var script := node.get_script() as GDScript
	if script:
		var cls: String = script.get_global_name()
		if not cls.is_empty():
			_capture_node_props(node, cls)
	for child in node.get_children():
		_scan_for_base_values(child)


func _capture_node_props(node: Node, cls: String) -> void:
	if not _base_values.has(cls):
		_base_values[cls] = {}
	for def: Dictionary in PROPERTY_DEFS:
		if def["class"] == cls:
			var val: Variant = node.get(def["name"])
			if val != null:
				_base_values[cls][def["name"]] = val


func set_override(cls: String, prop: String, value: Variant) -> void:
	if not _overrides.has(cls):
		_overrides[cls] = {}
	_overrides[cls][prop] = value
	if cls == "MusicManager":
		MusicManager.set(prop, value)


func get_override(cls: String, prop: String) -> Variant:
	if _overrides.has(cls) and _overrides[cls].has(prop):
		return _overrides[cls][prop]
	if _base_values.has(cls) and _base_values[cls].has(prop):
		return _base_values[cls][prop]
	return _get_default(cls, prop)


func reset_all() -> void:
	_overrides.clear()


func _get_default(cls: String, prop: String) -> Variant:
	for def in PROPERTY_DEFS:
		if def["class"] == cls and def["name"] == prop:
			return def["default"]
	return null


func _on_node_added(node: Node) -> void:
	var script := node.get_script() as GDScript
	if not script:
		return
	var cls: String = script.get_global_name()
	if cls.is_empty():
		return
	# Capture pre-override inspector values before applying any overrides.
	_capture_node_props(node, cls)
	_apply_class_overrides(node, cls)
	# Player2 inherits all Player overrides (movement + combat)
	if cls == "Player2":
		_apply_class_overrides(node, "Player")
	# Enemy receives only combat-related props from Player overrides
	elif cls == "Enemy" and _overrides.has("Player"):
		var player_ov: Dictionary = _overrides["Player"]
		for prop in _COMBAT_PROPS:
			if player_ov.has(prop):
				node.set(prop, player_ov[prop])


func _apply_class_overrides(node: Node, cls: String) -> void:
	if not _overrides.has(cls):
		return
	for prop: String in _overrides[cls]:
		node.set(prop, _overrides[cls][prop])
