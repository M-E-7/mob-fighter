extends Control
class_name MainMenu

const _LEVEL_SCENE := "res://Levels/LevelPrototype/basic_level.tscn"

const _COLOR_P1 := Color(0.0, 1.0, 0.9)
const _COLOR_P2 := Color(1.0, 0.6, 0.0)
const _COLOR_DIM := Color(0.45, 0.45, 0.5)
const _COLOR_READY := Color(0.2, 1.0, 0.35)
const _COLOR_BG_IDLE := Color(0.07, 0.07, 0.1, 1.0)
const _COLOR_BG_P1 := Color(0.0, 0.15, 0.18, 1.0)
const _COLOR_BG_P2 := Color(0.18, 0.1, 0.0, 1.0)
const _COLOR_BORDER_IDLE := Color(0.25, 0.25, 0.35, 1.0)
const _COLOR_BORDER_READY := Color(0.2, 1.0, 0.35, 1.0)

enum _SlotState { IDLE, JOINED, READY }

var _state_p1: _SlotState = _SlotState.IDLE
var _state_p2: _SlotState = _SlotState.IDLE

@onready var _title: Label = $CenterContainer/VBox/Title
@onready var _subtitle: Label = $CenterContainer/VBox/Subtitle
@onready var _slot_p1: PanelContainer = $CenterContainer/VBox/SlotsRow/SlotP1
@onready var _slot_p2: PanelContainer = $CenterContainer/VBox/SlotsRow/SlotP2
@onready var _name_p1: Label = $CenterContainer/VBox/SlotsRow/SlotP1/VBox/Name
@onready var _name_p2: Label = $CenterContainer/VBox/SlotsRow/SlotP2/VBox/Name
@onready var _status_p1: Label = $CenterContainer/VBox/SlotsRow/SlotP1/VBox/Status
@onready var _status_p2: Label = $CenterContainer/VBox/SlotsRow/SlotP2/VBox/Status
@onready var _quit_button: Button = $CenterContainer/VBox/QuitButton


func _ready() -> void:
	_apply_theme()
	_refresh_slot(1)
	_refresh_slot(2)
	_quit_button.pressed.connect(get_tree().quit)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and not event.is_echo() and event.pressed:
		_handle_keyboard(event as InputEventKey)
	elif event is InputEventJoypadButton and event.pressed:
		_handle_gamepad(event as InputEventJoypadButton)


func _handle_keyboard(event: InputEventKey) -> void:
	if _is_modifier_only(event):
		return
	var is_cancel := event.keycode == KEY_ESCAPE
	match _state_p1:
		_SlotState.IDLE:
			if is_cancel:
				get_tree().quit()
			else:
				_set_state_p1(_SlotState.JOINED)
		_SlotState.JOINED:
			if not is_cancel:
				_set_state_p1(_SlotState.READY)
		_SlotState.READY:
			if is_cancel:
				_set_state_p1(_SlotState.JOINED)


func _handle_gamepad(event: InputEventJoypadButton) -> void:
	var is_cancel := event.button_index == JOY_BUTTON_B
	match _state_p2:
		_SlotState.IDLE:
			if not is_cancel:
				_set_state_p2(_SlotState.JOINED)
		_SlotState.JOINED:
			if is_cancel:
				_set_state_p2(_SlotState.IDLE)
			else:
				_set_state_p2(_SlotState.READY)
		_SlotState.READY:
			if is_cancel:
				_set_state_p2(_SlotState.JOINED)


func _set_state_p1(new_state: _SlotState) -> void:
	_state_p1 = new_state
	_refresh_slot(1)
	_try_start()


func _set_state_p2(new_state: _SlotState) -> void:
	_state_p2 = new_state
	_refresh_slot(2)
	_try_start()


func _try_start() -> void:
	var p1_ready := _state_p1 == _SlotState.READY
	var p2_active := _state_p2 != _SlotState.IDLE
	var p2_ready := _state_p2 == _SlotState.READY
	if p1_ready and (not p2_active or p2_ready):
		GameConfig.player_count = 2 if p2_active else 1
		get_tree().change_scene_to_file(_LEVEL_SCENE)


func _refresh_slot(player: int) -> void:
	var state := _state_p1 if player == 1 else _state_p2
	var status_label := _status_p1 if player == 1 else _status_p2
	var name_label := _name_p1 if player == 1 else _name_p2
	var panel := _slot_p1 if player == 1 else _slot_p2
	var color_active := _COLOR_P1 if player == 1 else _COLOR_P2
	var bg_active := _COLOR_BG_P1 if player == 1 else _COLOR_BG_P2

	match state:
		_SlotState.IDLE:
			var prompt := "Press any key to join" if player == 1 else "Press any button to join"
			status_label.text = prompt
			status_label.modulate = _COLOR_DIM
			name_label.modulate = _COLOR_DIM
			_style_slot(panel, _COLOR_BG_IDLE, _COLOR_BORDER_IDLE)
		_SlotState.JOINED:
			status_label.text = "Press again to READY UP"
			status_label.modulate = color_active
			name_label.modulate = color_active
			_style_slot(panel, bg_active, color_active)
		_SlotState.READY:
			status_label.text = "READY!"
			status_label.modulate = _COLOR_READY
			name_label.modulate = _COLOR_READY
			_style_slot(panel, bg_active, _COLOR_BORDER_READY)


func _apply_theme() -> void:
	_title.add_theme_font_size_override("font_size", 96)
	_title.modulate = _COLOR_P1

	_subtitle.add_theme_font_size_override("font_size", 22)
	_subtitle.modulate = _COLOR_DIM

	_name_p1.add_theme_font_size_override("font_size", 34)
	_name_p2.add_theme_font_size_override("font_size", 34)
	_status_p1.add_theme_font_size_override("font_size", 18)
	_status_p2.add_theme_font_size_override("font_size", 18)

	var quit_normal := StyleBoxFlat.new()
	quit_normal.bg_color = Color(0.12, 0.04, 0.04)
	quit_normal.border_color = Color(0.6, 0.18, 0.18)
	quit_normal.set_border_width_all(2)
	quit_normal.set_corner_radius_all(4)
	quit_normal.content_margin_left = 40.0
	quit_normal.content_margin_right = 40.0
	quit_normal.content_margin_top = 12.0
	quit_normal.content_margin_bottom = 12.0
	_quit_button.add_theme_stylebox_override("normal", quit_normal)

	var quit_hover := quit_normal.duplicate() as StyleBoxFlat
	quit_hover.bg_color = Color(0.2, 0.06, 0.06)
	quit_hover.border_color = Color(0.9, 0.3, 0.3)
	_quit_button.add_theme_stylebox_override("hover", quit_hover)

	_quit_button.add_theme_color_override("font_color", Color(0.75, 0.25, 0.25))
	_quit_button.add_theme_color_override("font_hover_color", Color(1.0, 0.4, 0.4))
	_quit_button.add_theme_font_size_override("font_size", 22)
	_quit_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER


func _style_slot(panel: PanelContainer, bg: Color, border: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 48.0
	style.content_margin_right = 48.0
	style.content_margin_top = 32.0
	style.content_margin_bottom = 32.0
	panel.add_theme_stylebox_override("panel", style)


func _is_modifier_only(event: InputEventKey) -> bool:
	return event.keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META,
			KEY_CAPSLOCK, KEY_NUMLOCK, KEY_SCROLLLOCK]
