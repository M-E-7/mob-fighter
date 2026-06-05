extends CanvasLayer
class_name PauseMenuUI

const _MAIN_MENU_SCENE := "res://Levels/MainMenu/MainMenu.tscn"
const _COLOR_ACCENT := Color(0.0, 1.0, 0.9)
const _COLOR_DIM := Color(0.55, 0.55, 0.6)
const _COLOR_BG := Color(0.05, 0.05, 0.08, 0.95)

signal resume_requested

@onready var _continue_button: Button = $Dim/CenterContainer/VBox/ContinueButton
@onready var _menu_button: Button = $Dim/CenterContainer/VBox/MenuButton


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	_continue_button.pressed.connect(func() -> void: resume_requested.emit())
	_menu_button.pressed.connect(func() -> void:
		get_tree().paused = false
		MusicManager.stop()
		get_tree().change_scene_to_file(_MAIN_MENU_SCENE))
	_apply_style()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		resume_requested.emit()


func _apply_style() -> void:
	var title: Label = $Dim/CenterContainer/VBox/Title
	title.add_theme_font_size_override("font_size", 72)
	title.modulate = _COLOR_ACCENT

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = _COLOR_BG
	panel_style.border_color = Color(0.35, 0.35, 0.5)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 40.0
	panel_style.content_margin_right = 40.0
	panel_style.content_margin_top = 24.0
	panel_style.content_margin_bottom = 24.0

	_style_button(_continue_button, _COLOR_ACCENT, Color(0.0, 0.15, 0.18))
	_style_button(_menu_button, _COLOR_DIM, Color(0.07, 0.07, 0.12))


func _style_button(btn: Button, border: Color, bg: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.border_color = border
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(4)
	normal.content_margin_left = 48.0
	normal.content_margin_right = 48.0
	normal.content_margin_top = 14.0
	normal.content_margin_bottom = 14.0
	btn.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = bg.lightened(0.1)
	hover.border_color = border.lightened(0.2)
	btn.add_theme_stylebox_override("hover", hover)

	btn.add_theme_color_override("font_color", border)
	btn.add_theme_color_override("font_hover_color", border.lightened(0.25))
	btn.add_theme_font_size_override("font_size", 22)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
