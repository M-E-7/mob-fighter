extends Control
## P2 placeholder for the Sandbox shop (built in P3). Confirms the sector was cleared, returns to the menu.

const _MAIN_MENU_SCENE := "res://Levels/MainMenu/MainMenu.tscn"

@onready var _title: Label = $CenterContainer/VBox/Title
@onready var _menu_button: Button = $CenterContainer/VBox/MainMenuButton


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_title.text = "SANDBOX — SECTOR %d CLEARED" % RunState.current_level
	_menu_button.pressed.connect(_on_main_menu_pressed)


func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file(_MAIN_MENU_SCENE)
