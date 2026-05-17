extends Node2D

const _SVP1 := "SplitScreenLayout/SubViewportContainerP1/SubViewportP1"
const _SVP2 := "SplitScreenLayout/SubViewportContainerP2/SubViewportP2"

@onready var _subviewport_p1: SubViewport = get_node(_SVP1)
@onready var _subviewport_p2: SubViewport = get_node(_SVP2)
@onready var _proc_gen: ProcGenLevelComponent = get_node(_SVP1 + "/ProcGenLevelComponent")
@onready var _player1: LivingEntity = get_node(_SVP1 + "/Player")
@onready var _player2: LivingEntity = get_node(_SVP1 + "/Player2")
@onready var _spawner: EnemySpawnerComponent = get_node(_SVP1 + "/EnemySpawnerComponent")
@onready var _overlay_p1: Control = $SplitScreenLayout/OverlayP1
@onready var _overlay_p2: Control = $SplitScreenLayout/OverlayP2
@onready var _level_up_ui: Node = $LevelUpUI

var _camera_p1: Camera2D
var _camera_p2: Camera2D
var _p1_dead: bool = false
var _p2_dead: bool = false


func _ready() -> void:
	# SplitScreenLayout's parent is Node2D, so anchor resolution gives zero size.
	# Force it to the viewport size before anything else.
	$SplitScreenLayout.size = get_viewport().get_visible_rect().size

	# Both SubViewports share the main world (own_world_2d=false by default).
	# Camera2DP1 is parented to Player1 so it auto-follows without needing _process() sync.
	_camera_p1 = Camera2D.new()
	_player1.add_child(_camera_p1)

	# Camera2DP2 lives in SubViewportP2 and is position-synced to Player2 in _process().
	# Explicitly share SubViewportP1's world so P2's camera sees the same scene.
	_camera_p2 = Camera2D.new()
	_subviewport_p2.world_2d = _subviewport_p1.world_2d
	_subviewport_p2.add_child(_camera_p2)
	_camera_p2.global_position = _player2.global_position

	_level_up_ui.set("xp_component", _player1.get_node("XPComponent") as XPComponent)
	_level_up_ui.set("xp_component_p2", _player2.get_node("XPComponent") as XPComponent)

	_proc_gen.level_generated.connect(_on_level_generated)
	EventBus.entity_died.connect(_on_entity_died)


func _process(_delta: float) -> void:
	if not _p2_dead and is_instance_valid(_player2):
		_camera_p2.global_position = _player2.global_position


func _on_level_generated(spawn_pos: Vector2) -> void:
	_player1.global_position = spawn_pos
	_player2.global_position = spawn_pos + Vector2(60, 0)
	_camera_p2.global_position = spawn_pos + Vector2(60, 0)
	_spawner.start(_proc_gen)


func _on_entity_died(entity: LivingEntity) -> void:
	if entity == _player1:
		_p1_dead = true
		# Detach camera from player before player queue_frees so spectator view persists.
		if is_instance_valid(_camera_p1):
			_camera_p1.reparent(_subviewport_p1, true)
		_overlay_p1.visible = true
	elif entity == _player2:
		_p2_dead = true
		_overlay_p2.visible = true
