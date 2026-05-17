extends CanvasLayer

@export var card_count: int = 3
@export var xp_component: XPComponent

@onready var _cards_container: HBoxContainer = $BackgroundDim/CenterContainer/VBoxContainer/CardsContainer


func _ready() -> void:
	visible = false
	EventBus.player_leveled_up.connect(_on_player_leveled_up)


func _on_player_leveled_up(_player: LivingEntity) -> void:
	var picks := _pick_power_ups(card_count)
	_populate_cards(picks)
	visible = true
	get_tree().paused = true


func _pick_power_ups(count: int) -> Array[PowerUpData]:
	var pool := PowerUpRegistry.power_ups.duplicate()
	pool.shuffle()
	var result: Array[PowerUpData] = []
	for i in min(count, pool.size()):
		result.append(pool[i])
	return result


func _populate_cards(picks: Array[PowerUpData]) -> void:
	for child in _cards_container.get_children():
		child.queue_free()

	for power_up in picks:
		var card := _build_card(power_up)
		_cards_container.add_child(card)


func _build_card(power_up: PowerUpData) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(220, 140)

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
	# Capture power_up in closure via a bound callable
	btn.pressed.connect(_on_card_chosen.bind(power_up))
	vbox.add_child(btn)

	return panel


func _on_card_chosen(power_up: PowerUpData) -> void:
	if xp_component:
		xp_component.apply_power_up(power_up)
	visible = false
	get_tree().paused = false
