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

var _camera_p1: Camera2D
var _camera_p2: Camera2D
var _p1_dead: bool = false
var _p2_dead: bool = false
var _hud: HUD
var _pause_menu: PauseMenuUI
var _game_over_shown: bool = false


func _ready() -> void:
	# SplitScreenLayout's parent is Node2D, so anchor resolution gives zero size.
	# Force it to the viewport size before anything else.
	$SplitScreenLayout.size = get_viewport().get_visible_rect().size

	_camera_p1 = Camera2D.new()
	_subviewport_p1.add_child(_camera_p1)
	var input_comp_p1 := _player1.get_node_or_null("PlayerInputComponent") as PlayerInputComponent

	var fixed_cam_p1 := preload("res://Components/FixedCameraComponent.tscn").instantiate() as FixedCameraComponent
	add_child(fixed_cam_p1)
	fixed_cam_p1.setup(_player1, _camera_p1)

	var rel_cam_p1 := preload("res://Components/RelativeCameraComponent.tscn").instantiate() as RelativeCameraComponent
	add_child(rel_cam_p1)
	rel_cam_p1.setup(_player1, _camera_p1, input_comp_p1)

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
	# P2's camera lives in SubViewportP2, sharing SubViewportP1's world_2d so it sees the same scene.
	_camera_p2 = Camera2D.new()
	_subviewport_p2.world_2d = _subviewport_p1.world_2d
	_subviewport_p2.add_child(_camera_p2)
	_camera_p2.global_position = _player2.global_position

	var fixed_cam_p2 := preload("res://Components/FixedCameraComponent.tscn").instantiate() as FixedCameraComponent
	add_child(fixed_cam_p2)
	fixed_cam_p2.setup(_player2, _camera_p2)


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
	if event.is_action_pressed("toggle_camera_mode") and not _game_over_shown:
		_toggle_camera_mode()
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


func _toggle_camera_mode() -> void:
	GameConfig.camera_relative_mode = not GameConfig.camera_relative_mode
	if GameConfig.camera_relative_mode:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _show_game_over() -> void:
	_game_over_shown = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	MusicManager.stop()
	GameConfig.result_kills_p1 = _hud.get_kills(1)
	GameConfig.result_kills_p2 = _hud.get_kills(2)
	GameConfig.result_survival_time = _hud.get_survival_time()
	GameConfig.result_currency = RunState.currency
	var go := preload("res://UI/GameOverUI.tscn").instantiate() as GameOverUI
	add_child(go)
	go.setup(GameConfig.player_count)
