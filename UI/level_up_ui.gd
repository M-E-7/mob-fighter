extends CanvasLayer
class_name LevelUpUI

@export var card_count: int = 3
@export var xp_component: XPComponent
@export var xp_component_p2: XPComponent

@onready var _cards_p1: HBoxContainer = $BackgroundDim/CenterContainer/VBoxContainer/PlayersHBox/P1Section/CardsContainerP1
@onready var _cards_p2: HBoxContainer = $BackgroundDim/CenterContainer/VBoxContainer/PlayersHBox/P2Section/CardsContainerP2
@onready var _p2_section: VBoxContainer = $BackgroundDim/CenterContainer/VBoxContainer/PlayersHBox/P2Section
@onready var _p2_separator: VSeparator = $BackgroundDim/CenterContainer/VBoxContainer/PlayersHBox/VSeparator
@onready var _title_label: Label = $BackgroundDim/CenterContainer/VBoxContainer/TitleLabel

var _p2_picks: Array[PowerUpData] = []
var _p2_card_panels: Array[PanelContainer] = []
var _p2_selected: int = 0
var _p1_picked: bool = false
var _p2_picked: bool = false


func _ready() -> void:
	visible = false
	if GameConfig.player_count == 1:
		_p2_section.hide()
		_p2_separator.hide()
		_title_label.text = "Level Up! Choose your power-up:"
	EventBus.player_leveled_up.connect(_on_player_leveled_up)


func _input(event: InputEvent) -> void:
	if not visible or _p2_picked:
		return

	if event.is_action_pressed("p2_ui_left"):
		_p2_selected = max(0, _p2_selected - 1)
		_update_p2_highlight()

	elif event.is_action_pressed("p2_ui_right"):
		_p2_selected = min(_p2_card_panels.size() - 1, _p2_selected + 1)
		_update_p2_highlight()

	elif event.is_action_pressed("p2_confirm"):
		if _p2_card_panels.size() > 0:
			_on_p2_card_chosen(_p2_picks[_p2_selected])


func _on_player_leveled_up(_player: LivingEntity) -> void:
	_p1_picked = false
	_p2_picked = false

	var p1_picks := _pick_power_ups(card_count)
	_populate_p1_cards(p1_picks)

	_p2_picks = _pick_power_ups(card_count)
	_p2_selected = 0
	_populate_p2_cards(_p2_picks)

	# If P2 has no XPComponent (e.g. player dead), auto-skip P2
	if not is_instance_valid(xp_component_p2):
		_p2_picked = true
		_p2_section.modulate = Color(0.4, 0.4, 0.4, 1.0)
	else:
		_p2_section.modulate = Color(1, 1, 1, 1)

	visible = true
	get_tree().paused = true


func _pick_power_ups(count: int) -> Array[PowerUpData]:
	var pool := PowerUpRegistry.power_ups.duplicate()
	pool.shuffle()
	var result: Array[PowerUpData] = []
	for i in min(count, pool.size()):
		result.append(pool[i])
	return result


func _populate_p1_cards(picks: Array[PowerUpData]) -> void:
	for child in _cards_p1.get_children():
		child.queue_free()
	for power_up in picks:
		var card := _build_p1_card(power_up)
		_cards_p1.add_child(card)


func _populate_p2_cards(picks: Array[PowerUpData]) -> void:
	for child in _cards_p2.get_children():
		child.queue_free()
	_p2_card_panels.clear()
	for power_up in picks:
		var card := _build_p2_card(power_up)
		_cards_p2.add_child(card)
		_p2_card_panels.append(card)
	_update_p2_highlight()


func _build_p1_card(power_up: PowerUpData) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(200, 130)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var name_label := Label.new()
	name_label.text = power_up.display_name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = power_up.description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc_label)

	var btn := Button.new()
	btn.text = "Choose"
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(_on_p1_card_chosen.bind(power_up))
	vbox.add_child(btn)

	return panel


func _build_p2_card(power_up: PowerUpData) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(200, 130)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var name_label := Label.new()
	name_label.text = power_up.display_name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = power_up.description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc_label)

	var hint := Label.new()
	hint.text = "◄ ► to navigate · A to confirm"
	hint.add_theme_font_size_override("font_size", 12)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color(0.8, 0.8, 0.8, 1.0)
	vbox.add_child(hint)

	return panel


func _update_p2_highlight() -> void:
	for i in _p2_card_panels.size():
		_p2_card_panels[i].modulate = Color(1.0, 0.6, 0.1, 1.0) if i == _p2_selected else Color(1, 1, 1, 1)


func _on_p1_card_chosen(power_up: PowerUpData) -> void:
	if _p1_picked:
		return
	_p1_picked = true
	if is_instance_valid(xp_component):
		xp_component.apply_power_up(power_up)
	_try_close()


func _on_p2_card_chosen(power_up: PowerUpData) -> void:
	if _p2_picked:
		return
	_p2_picked = true
	if is_instance_valid(xp_component_p2):
		xp_component_p2.apply_power_up(power_up)
	_update_p2_highlight()
	_try_close()


func _try_close() -> void:
	if _p1_picked and _p2_picked:
		visible = false
		get_tree().paused = false
