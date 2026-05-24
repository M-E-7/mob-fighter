extends CanvasLayer
class_name GameOverUI

const _MAIN_MENU_SCENE := "res://Levels/MainMenu/MainMenu.tscn"

const _COLOR_ACCENT := Color(0.0, 1.0, 0.9)
const _COLOR_DIM := Color(0.55, 0.55, 0.6)
const _COLOR_BG := Color(0.05, 0.05, 0.08, 0.95)

@onready var _title: Label = $Dim/CenterContainer/VBox/Title
@onready var _time_label: Label = $Dim/CenterContainer/VBox/StatsPanel/StatsVBox/TimeLabel
@onready var _p1_label: Label = $Dim/CenterContainer/VBox/StatsPanel/StatsVBox/P1Label
@onready var _p2_label: Label = $Dim/CenterContainer/VBox/StatsPanel/StatsVBox/P2Label
@onready var _retry_button: Button = $Dim/CenterContainer/VBox/RetryButton
@onready var _menu_button: Button = $Dim/CenterContainer/VBox/MenuButton


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS


func setup(player_count: int) -> void:
	var t := GameConfig.result_survival_time
	_time_label.text = "Survived: %d:%02d" % [int(t) / 60, int(t) % 60]
	_p1_label.text = "P1 — Level %d · %d kills" % [
		GameConfig.result_level_p1 + 1, GameConfig.result_kills_p1]
	if player_count == 2:
		_p2_label.text = "P2 — Level %d · %d kills" % [
			GameConfig.result_level_p2 + 1, GameConfig.result_kills_p2]
	else:
		_p2_label.hide()
	_retry_button.pressed.connect(func() -> void: get_tree().reload_current_scene())
	_menu_button.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(_MAIN_MENU_SCENE))
	_apply_theme()


func _apply_theme() -> void:
	_title.add_theme_font_size_override("font_size", 72)
	_title.modulate = Color(1.0, 0.25, 0.25)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = _COLOR_BG
	panel_style.border_color = Color(0.35, 0.35, 0.5)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 40.0
	panel_style.content_margin_right = 40.0
	panel_style.content_margin_top = 24.0
	panel_style.content_margin_bottom = 24.0
	$Dim/CenterContainer/VBox/StatsPanel.add_theme_stylebox_override("panel", panel_style)

	for lbl in [$Dim/CenterContainer/VBox/StatsPanel/StatsVBox/TimeLabel,
			$Dim/CenterContainer/VBox/StatsPanel/StatsVBox/P1Label,
			$Dim/CenterContainer/VBox/StatsPanel/StatsVBox/P2Label]:
		(lbl as Label).add_theme_font_size_override("font_size", 22)
		(lbl as Label).modulate = Color(0.9, 0.9, 1.0)

	_style_button(_retry_button, _COLOR_ACCENT, Color(0.0, 0.15, 0.18))
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
