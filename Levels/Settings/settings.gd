extends Control
class_name Settings

const _MAIN_MENU_SCENE := "res://Levels/MainMenu/MainMenu.tscn"
const _ADVANCED_SCENE := "res://Levels/Settings/AdvancedSettings.tscn"

const _COLOR_ACCENT := Color(0.0, 1.0, 0.9)
const _COLOR_DIM := Color(0.45, 0.45, 0.5)

@onready var _title: Label = $CenterContainer/VBox/Title
@onready var _health_toggle: CheckButton = $CenterContainer/VBox/TogglesPanel/TogglesVBox/HealthRow/HealthToggle
@onready var _xp_toggle: CheckButton = $CenterContainer/VBox/TogglesPanel/TogglesVBox/XPRow/XPToggle
@onready var _kills_toggle: CheckButton = $CenterContainer/VBox/TogglesPanel/TogglesVBox/KillsRow/KillsToggle
@onready var _powerups_toggle: CheckButton = $CenterContainer/VBox/TogglesPanel/TogglesVBox/PowerupsRow/PowerupsToggle
@onready var _damage_num_toggle: CheckButton = $CenterContainer/VBox/TogglesPanel/TogglesVBox/DamageNumRow/DamageNumToggle
@onready var _low_hp_toggle: CheckButton = $CenterContainer/VBox/TogglesPanel/TogglesVBox/LowHPRow/LowHPToggle
@onready var _xp_flash_toggle: CheckButton = $CenterContainer/VBox/TogglesPanel/TogglesVBox/XPFlashRow/XPFlashToggle
@onready var _timer_toggle: CheckButton = $CenterContainer/VBox/TogglesPanel/TogglesVBox/TimerRow/TimerToggle
@onready var _xp_pickup_toggle: CheckButton = $CenterContainer/VBox/TogglesPanel/TogglesVBox/XPPickupRow/XPPickupToggle
@onready var _music_visuals_toggle: CheckButton = $CenterContainer/VBox/TogglesPanel/TogglesVBox/MusicVisualsRow/MusicVisualsToggle
@onready var _music_visualizer_toggle: CheckButton = $CenterContainer/VBox/TogglesPanel/TogglesVBox/MusicVisualizerRow/MusicVisualizerToggle
@onready var _camera_panel: PanelContainer = $CenterContainer/VBox/TogglesPanel/TogglesVBox/CameraPanel
@onready var _camera_vbox: VBoxContainer = $CenterContainer/VBox/TogglesPanel/TogglesVBox/CameraPanel/CameraVBox
@onready var _camera_header: Label = $CenterContainer/VBox/TogglesPanel/TogglesVBox/CameraPanel/CameraVBox/CameraHeader
@onready var _camera_toggle: CheckButton = $CenterContainer/VBox/TogglesPanel/TogglesVBox/CameraPanel/CameraVBox/CameraRow/CameraToggle
@onready var _sensitivity_slider: HSlider = $CenterContainer/VBox/TogglesPanel/TogglesVBox/CameraPanel/CameraVBox/SensitivityRow/SensitivitySlider
@onready var _sensitivity_value_label: Label = $CenterContainer/VBox/TogglesPanel/TogglesVBox/CameraPanel/CameraVBox/SensitivityRow/SensitivityValueLabel
@onready var _smoothing_slider: HSlider = $CenterContainer/VBox/TogglesPanel/TogglesVBox/CameraPanel/CameraVBox/SmoothingRow/SmoothingSlider
@onready var _smoothing_value_label: Label = $CenterContainer/VBox/TogglesPanel/TogglesVBox/CameraPanel/CameraVBox/SmoothingRow/SmoothingValueLabel
@onready var _advanced_button: Button = $CenterContainer/VBox/AdvancedButton
@onready var _back_button: Button = $CenterContainer/VBox/BackButton


func _ready() -> void:
	_apply_theme()
	_health_toggle.button_pressed = GameConfig.hud_show_health
	_xp_toggle.button_pressed = GameConfig.hud_show_xp
	_kills_toggle.button_pressed = GameConfig.hud_show_kills
	_powerups_toggle.button_pressed = GameConfig.hud_show_powerups
	_health_toggle.toggled.connect(func(v: bool) -> void: GameConfig.hud_show_health = v)
	_xp_toggle.toggled.connect(func(v: bool) -> void: GameConfig.hud_show_xp = v)
	_kills_toggle.toggled.connect(func(v: bool) -> void: GameConfig.hud_show_kills = v)
	_powerups_toggle.toggled.connect(func(v: bool) -> void: GameConfig.hud_show_powerups = v)
	_damage_num_toggle.button_pressed = GameConfig.hud_show_damage_numbers
	_low_hp_toggle.button_pressed = GameConfig.hud_show_low_hp_warning
	_xp_flash_toggle.button_pressed = GameConfig.hud_show_xp_flash
	_timer_toggle.button_pressed = GameConfig.hud_show_survival_timer
	_xp_pickup_toggle.button_pressed = GameConfig.hud_show_xp_pickup_text
	_music_visuals_toggle.button_pressed = GameConfig.music_visuals_enabled
	_music_visualizer_toggle.button_pressed = GameConfig.show_music_visualizer
	_damage_num_toggle.toggled.connect(func(v: bool) -> void: GameConfig.hud_show_damage_numbers = v)
	_low_hp_toggle.toggled.connect(func(v: bool) -> void: GameConfig.hud_show_low_hp_warning = v)
	_xp_flash_toggle.toggled.connect(func(v: bool) -> void: GameConfig.hud_show_xp_flash = v)
	_timer_toggle.toggled.connect(func(v: bool) -> void: GameConfig.hud_show_survival_timer = v)
	_xp_pickup_toggle.toggled.connect(func(v: bool) -> void: GameConfig.hud_show_xp_pickup_text = v)
	_music_visuals_toggle.toggled.connect(func(v: bool) -> void: GameConfig.music_visuals_enabled = v)
	_music_visualizer_toggle.toggled.connect(func(v: bool) -> void: GameConfig.show_music_visualizer = v)
	_camera_toggle.button_pressed = GameConfig.camera_relative_mode
	_camera_toggle.toggled.connect(func(v: bool) -> void: GameConfig.camera_relative_mode = v)
	_sensitivity_slider.scrollable = false
	_smoothing_slider.scrollable = false
	_sensitivity_slider.value = GameConfig.mouse_sensitivity * 1000.0
	_sensitivity_value_label.text = str(int(_sensitivity_slider.value))
	_sensitivity_slider.value_changed.connect(func(v: float) -> void:
		GameConfig.mouse_sensitivity = v / 1000.0
		_sensitivity_value_label.text = str(int(v))
	)
	_smoothing_slider.value = GameConfig.camera_smoothing
	_smoothing_value_label.text = str(int(_smoothing_slider.value))
	_smoothing_slider.value_changed.connect(func(v: float) -> void:
		GameConfig.camera_smoothing = v
		_smoothing_value_label.text = str(int(v))
	)
	_advanced_button.pressed.connect(_on_advanced_pressed)
	_back_button.pressed.connect(_on_back_pressed)


func _on_advanced_pressed() -> void:
	get_tree().change_scene_to_file(_ADVANCED_SCENE)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(_MAIN_MENU_SCENE)


func _apply_theme() -> void:
	_title.add_theme_font_size_override("font_size", 72)
	_title.modulate = _COLOR_ACCENT

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.07, 0.07, 0.12)
	panel_style.border_color = Color(0.2, 0.2, 0.35)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 32.0
	panel_style.content_margin_right = 32.0
	panel_style.content_margin_top = 24.0
	panel_style.content_margin_bottom = 24.0
	$CenterContainer/VBox/TogglesPanel.add_theme_stylebox_override("panel", panel_style)

	var toggles_vbox: VBoxContainer = $CenterContainer/VBox/TogglesPanel/TogglesVBox
	for row in toggles_vbox.get_children():
		if row is HBoxContainer:
			var lbl := row.get_child(0) as Label
			if lbl:
				lbl.add_theme_font_size_override("font_size", 18)
				lbl.modulate = Color(0.85, 0.85, 0.9)

	var cam_style := StyleBoxFlat.new()
	cam_style.bg_color = Color(0.03, 0.07, 0.11, 1.0)
	cam_style.border_color = Color(0.0, 0.5, 0.6)
	cam_style.set_border_width_all(1)
	cam_style.set_corner_radius_all(6)
	cam_style.content_margin_left = 12.0
	cam_style.content_margin_right = 12.0
	cam_style.content_margin_top = 10.0
	cam_style.content_margin_bottom = 10.0
	_camera_panel.add_theme_stylebox_override("panel", cam_style)

	_camera_header.add_theme_font_size_override("font_size", 13)
	_camera_header.modulate = _COLOR_ACCENT

	for row in _camera_vbox.get_children():
		if row is HBoxContainer:
			var lbl := row.get_child(0) as Label
			if lbl:
				lbl.add_theme_font_size_override("font_size", 18)
				lbl.modulate = Color(0.85, 0.85, 0.9)

	var adv_normal := StyleBoxFlat.new()
	adv_normal.bg_color = Color(0.05, 0.1, 0.12)
	adv_normal.border_color = Color(0.2, 0.5, 0.55)
	adv_normal.set_border_width_all(2)
	adv_normal.set_corner_radius_all(4)
	adv_normal.content_margin_left = 40.0
	adv_normal.content_margin_right = 40.0
	adv_normal.content_margin_top = 12.0
	adv_normal.content_margin_bottom = 12.0
	_advanced_button.add_theme_stylebox_override("normal", adv_normal)

	var adv_hover := adv_normal.duplicate() as StyleBoxFlat
	adv_hover.bg_color = Color(0.08, 0.15, 0.18)
	adv_hover.border_color = _COLOR_ACCENT
	_advanced_button.add_theme_stylebox_override("hover", adv_hover)

	_advanced_button.add_theme_color_override("font_color", Color(0.5, 0.8, 0.85))
	_advanced_button.add_theme_color_override("font_hover_color", _COLOR_ACCENT)
	_advanced_button.add_theme_font_size_override("font_size", 22)
	_advanced_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var back_normal := StyleBoxFlat.new()
	back_normal.bg_color = Color(0.07, 0.07, 0.12)
	back_normal.border_color = Color(0.3, 0.3, 0.5)
	back_normal.set_border_width_all(2)
	back_normal.set_corner_radius_all(4)
	back_normal.content_margin_left = 40.0
	back_normal.content_margin_right = 40.0
	back_normal.content_margin_top = 12.0
	back_normal.content_margin_bottom = 12.0
	_back_button.add_theme_stylebox_override("normal", back_normal)

	var back_hover := back_normal.duplicate() as StyleBoxFlat
	back_hover.bg_color = Color(0.1, 0.1, 0.18)
	back_hover.border_color = _COLOR_ACCENT
	_back_button.add_theme_stylebox_override("hover", back_hover)

	_back_button.add_theme_color_override("font_color", _COLOR_DIM)
	_back_button.add_theme_color_override("font_hover_color", _COLOR_ACCENT)
	_back_button.add_theme_font_size_override("font_size", 22)
	_back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
