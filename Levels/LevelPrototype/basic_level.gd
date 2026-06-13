extends Node2D

const _SVP1 := "SplitScreenLayout/SubViewportContainerP1/SubViewportP1"
const _SVP2 := "SplitScreenLayout/SubViewportContainerP2/SubViewportP2"

@onready var _subviewport_p1: SubViewport = get_node(_SVP1)
@onready var _subviewport_p2: SubViewport = get_node(_SVP2)
@onready var _container_p1: SubViewportContainer = $SplitScreenLayout/SubViewportContainerP1
@onready var _container_p2: SubViewportContainer = $SplitScreenLayout/SubViewportContainerP2
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
var _hud: HUD
var _pause_menu: PauseMenuUI
var _game_over_shown: bool = false
var _rel_cam_angle: float = 0.0
var _display_cam_angle: float = 0.0
var _look_ahead_angle: float = 0.0
var _input_comp_p1: PlayerInputComponent


func _ready() -> void:
	# SplitScreenLayout's parent is Node2D, so anchor resolution gives zero size.
	# Force it to the viewport size before anything else.
	$SplitScreenLayout.size = get_viewport().get_visible_rect().size

	_camera_p1 = Camera2D.new()
	_subviewport_p1.add_child(_camera_p1)
	_input_comp_p1 = _player1.get_node_or_null("PlayerInputComponent") as PlayerInputComponent

	_level_up_ui.set("xp_component", _player1.get_node("XPComponent") as XPComponent)

	if GameConfig.player_count == 1:
		_setup_single_player()
	else:
		_setup_split_screen()

	_hud = preload("res://UI/HUD.tscn").instantiate() as HUD
	add_child(_hud)
	_hud.setup(_player1, _player2, GameConfig.player_count)

	var music_viz := preload("res://UI/MusicVisualizerHUD.tscn").instantiate()
	add_child(music_viz)

	var ftm := preload("res://UI/FloatingTextManager.tscn").instantiate()
	_subviewport_p1.add_child(ftm)

	var vis := LevelVisualsController.new()
	add_child(vis)
	var rects: Array[ColorRect] = []
	var bg_cams: Array[Camera2D] = []
	var bg_p1 := _subviewport_p1.get_node_or_null("BackgroundLayer/NeonBackground") as ColorRect
	if bg_p1:
		rects.append(bg_p1)
		bg_cams.append(_camera_p1)
	if GameConfig.player_count == 2:
		var bg_p2 := _subviewport_p2.get_node_or_null("BackgroundLayer/NeonBackground") as ColorRect
		if bg_p2:
			rects.append(bg_p2)
			bg_cams.append(_camera_p2)
	vis.setup(rects, _proc_gen, bg_cams)

	var shake := ScreenShakeController.new()
	add_child(shake)
	var shake_cams: Array[Camera2D] = [_camera_p1]
	var shake_players: Array[LivingEntity] = [_player1]
	if GameConfig.player_count == 2:
		shake_cams.append(_camera_p2)
		shake_players.append(_player2)
	shake.setup(shake_cams, shake_players)

	if GameConfig.camera_relative_mode:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	MusicManager.start()

	_proc_gen.level_generated.connect(_on_level_generated)
	EventBus.entity_died.connect(_on_entity_died)


func _setup_single_player() -> void:
	_container_p2.hide()
	_overlay_p2.hide()
	_container_p1.size = get_viewport().get_visible_rect().size
	_player2.queue_free()
	_player2 = null


func _setup_split_screen() -> void:
	# Camera2DP2 lives in SubViewportP2 and is position-synced to Player2 in _process().
	# Explicitly share SubViewportP1's world so P2's camera sees the same scene.
	_camera_p2 = Camera2D.new()
	_subviewport_p2.world_2d = _subviewport_p1.world_2d
	_subviewport_p2.add_child(_camera_p2)
	_camera_p2.global_position = _player2.global_position
	_level_up_ui.set("xp_component_p2", _player2.get_node("XPComponent") as XPComponent)


func _process(delta: float) -> void:
	if GameConfig.camera_relative_mode:
		_camera_p1.ignore_rotation = false
		var rot_w := 1.0 - exp(-GameConfig.camera_smoothing * delta)
		_display_cam_angle = lerp_angle(_display_cam_angle, _rel_cam_angle, rot_w)
		_camera_p1.global_rotation = _display_cam_angle
		if not _p1_dead:
			var la_w := 1.0 - exp(-GameConfig.camera_look_ahead_smoothing * delta)
			_look_ahead_angle = lerp_angle(_look_ahead_angle, _rel_cam_angle, la_w)
			var fwd := Vector2(sin(_look_ahead_angle), -cos(_look_ahead_angle))
			_camera_p1.global_position = _player1.global_position + fwd * GameConfig.camera_look_ahead
		if _input_comp_p1:
			_input_comp_p1.relative_camera_angle = _rel_cam_angle
	else:
		_camera_p1.ignore_rotation = true
		if not _p1_dead:
			_camera_p1.global_position = _player1.global_position

	if GameConfig.player_count == 2 and not _p2_dead and is_instance_valid(_player2):
		_camera_p2.global_position = _player2.global_position


func _on_level_generated(spawn_pos: Vector2) -> void:
	_player1.global_position = spawn_pos
	_camera_p1.global_position = spawn_pos
	if is_instance_valid(_player2):
		_player2.global_position = spawn_pos + Vector2(60, 0)
		_camera_p2.global_position = spawn_pos + Vector2(60, 0)
	_spawner.start(_proc_gen)


func _on_entity_died(entity: LivingEntity) -> void:
	if entity == _player1:
		_p1_dead = true
		_overlay_p1.visible = true
	elif is_instance_valid(_player2) and entity == _player2:
		_p2_dead = true
		_overlay_p2.visible = true

	var all_dead := _p1_dead and (GameConfig.player_count == 1 or _p2_dead)
	if all_dead:
		_show_game_over()


func _unhandled_input(event: InputEvent) -> void:
	if GameConfig.camera_relative_mode and event is InputEventMouseMotion:
		_rel_cam_angle += (event as InputEventMouseMotion).relative.x * GameConfig.mouse_sensitivity
		return
	if event.is_action_pressed("ui_cancel") and not _game_over_shown:
		_pause_game()


func _pause_game() -> void:
	if not is_instance_valid(_pause_menu):
		_pause_menu = preload("res://UI/PauseMenuUI.tscn").instantiate() as PauseMenuUI
		add_child(_pause_menu)
		_pause_menu.resume_requested.connect(_resume_game)
	_pause_menu.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true


func _resume_game() -> void:
	get_tree().paused = false
	if GameConfig.camera_relative_mode:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if is_instance_valid(_pause_menu):
		_pause_menu.visible = false


func _show_game_over() -> void:
	_game_over_shown = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	MusicManager.stop()
	GameConfig.result_kills_p1 = _hud.get_kills(1)
	GameConfig.result_kills_p2 = _hud.get_kills(2)
	GameConfig.result_survival_time = _hud.get_survival_time()
	var xp1 := _player1.get_node_or_null("XPComponent") as XPComponent if is_instance_valid(_player1) else null
	GameConfig.result_level_p1 = xp1.current_level if xp1 else 0
	var xp2 := _player2.get_node_or_null("XPComponent") as XPComponent if is_instance_valid(_player2) else null
	GameConfig.result_level_p2 = xp2.current_level if xp2 else 0
	var go := preload("res://UI/GameOverUI.tscn").instantiate() as GameOverUI
	add_child(go)
	go.setup(GameConfig.player_count)
