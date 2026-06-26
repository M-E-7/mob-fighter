extends Control

const _MAIN_MENU_SCENE := "res://Levels/MainMenu/MainMenu.tscn"
const _LEVEL_SCENE := "res://Levels/LevelPrototype/basic_level.tscn"
const _CARDS_SHOWN := 3

@onready var _bits_label: Label = $MarginContainer/Layout/Header/BitsLabel
@onready var _sector_label: Label = $MarginContainer/Layout/SectorLabel
@onready var _cards_row: HBoxContainer = $MarginContainer/Layout/CardsRow
@onready var _reroll_button: Button = $MarginContainer/Layout/BottomRows/RerollRow/RerollButton
@onready var _integrity_label: Label = $MarginContainer/Layout/BottomRows/RepairRow/IntegrityLabel
@onready var _repair_button: Button = $MarginContainer/Layout/BottomRows/RepairRow/RepairButton
@onready var _continue_button: Button = $MarginContainer/Layout/BottomRows/FooterRow/ContinueButton
@onready var _abandon_button: Button = $MarginContainer/Layout/BottomRows/FooterRow/AbandonButton

# Holds PowerUpData (Upgrades) and/or ModifierData (Daemons) — branch on `entry is ModifierData`.
var _stock: Array = []
var _reroll_count: int = 0

const _DAEMON_TINT := Color(1.0, 0.55, 0.95)

# P2 keyboard navigation — parallel arrays: visual node to highlight, button to press
var _p2_highlight_nodes: Array[Control] = []
var _p2_buttons: Array[Button] = []
var _p2_cursor: int = 0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_sector_label.text = "SECTOR %d CLEARED" % RunState.current_level
	_set_bits(RunState.currency)
	EventBus.currency_changed.connect(_on_currency_changed)

	_reroll_button.pressed.connect(_on_reroll_pressed)
	_repair_button.pressed.connect(_on_repair_pressed)
	_continue_button.pressed.connect(_on_continue_pressed)
	_abandon_button.pressed.connect(_on_abandon_pressed)

	_draw_stock()
	_refresh_repair()


func _unhandled_input(event: InputEvent) -> void:
	if GameConfig.player_count < 2:
		return
	if event.is_action_pressed("p2_ui_left"):
		_p2_move(-1)
	elif event.is_action_pressed("p2_ui_right"):
		_p2_move(1)
	elif event.is_action_pressed("p2_confirm"):
		_p2_confirm()


# --- Stock management ---

func _draw_stock() -> void:
	_stock = _pick_stock()
	for child in _cards_row.get_children():
		_cards_row.remove_child(child)
		child.queue_free()
	for entry: Variant in _stock:
		_cards_row.add_child(_build_card(entry))
	_refresh_reroll_button()
	_refresh_cards()
	_rebuild_p2_interactables()


func _pick_stock() -> Array:
	var pool: Array = []
	for up: PowerUpData in PowerUpRegistry.power_ups:
		pool.append(up)
	for m: ModifierData in ModifierRegistry.modifiers:
		# Exclude Daemons already maxed out (unless unlimited stacks).
		if m.max_stacks == 0 or RunState.modifier_stacks(m.id) < m.max_stacks:
			pool.append(m)
	pool.shuffle()
	var result: Array = []
	for i: int in min(_CARDS_SHOWN, pool.size()):
		result.append(pool[i])
	return result


func _build_card(entry: Variant) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(260, 160)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var is_daemon := entry is ModifierData

	var name_lbl := Label.new()
	name_lbl.text = entry.display_name
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if is_daemon:
		name_lbl.modulate = _DAEMON_TINT
	vbox.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = ("[DAEMON] " + entry.description) if is_daemon else entry.description
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc_lbl)

	var owned_lbl := Label.new()
	owned_lbl.add_theme_font_size_override("font_size", 13)
	owned_lbl.modulate = Color(0.7, 0.8, 1.0)
	owned_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(owned_lbl)

	var btn := Button.new()
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(_on_buy_pressed.bind(entry))
	vbox.add_child(btn)

	return panel


func _refresh_cards() -> void:
	var cards := _cards_row.get_children()
	for i: int in cards.size():
		if i >= _stock.size():
			break
		var entry: Variant = _stock[i]
		var panel := cards[i] as PanelContainer
		if not panel:
			continue
		var vbox := panel.get_child(0) as VBoxContainer
		if not vbox:
			continue
		var owned_lbl := vbox.get_child(2) as Label
		var btn := vbox.get_child(3) as Button
		if entry is ModifierData:
			var cost: int = RunState.modifier_cost(entry)
			var maxed: bool = entry.max_stacks != 0 and RunState.modifier_stacks(entry.id) >= entry.max_stacks
			if owned_lbl:
				owned_lbl.text = "Owned: %d" % RunState.modifier_stacks(entry.id)
			if btn:
				btn.text = "MAXED" if maxed else "INSTALL — %d Bits" % cost
				btn.disabled = not RunState.can_buy_modifier(entry)
		else:
			var cost := RunState.upgrade_cost(entry)
			if owned_lbl:
				owned_lbl.text = "Owned: %d" % RunState.owned_upgrades.get(entry.stat_key, 0)
			if btn:
				btn.text = "BUY — %d Bits" % cost
				btn.disabled = not RunState.can_afford(cost)


func _refresh_reroll_button() -> void:
	var cost := _reroll_cost()
	_reroll_button.text = "REROLL (%d Bits)" % cost
	_reroll_button.disabled = not RunState.can_afford(cost)


func _reroll_cost() -> int:
	return 5 + _reroll_count * 5


func _refresh_repair() -> void:
	var frac := _min_health_fraction()
	_integrity_label.text = "Integrity: %d%%" % int(frac * 100.0)
	var cost := RunState.repair_cost()
	_repair_button.text = "Repair +34%% (%d Bits)" % cost
	_repair_button.disabled = frac >= 1.0 or not RunState.can_afford(cost)


func _min_health_fraction() -> float:
	var f: float = RunState.health_fraction[0]
	if GameConfig.player_count == 2:
		f = minf(f, RunState.health_fraction[1])
	return f


# --- Button handlers ---

func _on_buy_pressed(entry: Variant) -> void:
	var bought: bool = RunState.buy_modifier(entry) if entry is ModifierData else RunState.buy_upgrade(entry)
	if bought:
		_refresh_cards()
		_refresh_reroll_button()
		_refresh_repair()
		_rebuild_p2_interactables()


func _on_reroll_pressed() -> void:
	var cost := _reroll_cost()
	if not RunState.can_afford(cost):
		return
	RunState.currency -= cost
	EventBus.currency_changed.emit(RunState.currency)
	_reroll_count += 1
	_draw_stock()
	_refresh_repair()


func _on_repair_pressed() -> void:
	if RunState.repair(GameConfig.player_count):
		_refresh_repair()
		_refresh_reroll_button()
		_refresh_cards()


func _on_continue_pressed() -> void:
	RunState.current_level += 1
	get_tree().change_scene_to_file(_LEVEL_SCENE)


func _on_abandon_pressed() -> void:
	RunState.reset()
	get_tree().change_scene_to_file(_MAIN_MENU_SCENE)


# --- Currency display ---

func _set_bits(total: int) -> void:
	_bits_label.text = "%d Bits" % total


func _on_currency_changed(total: int) -> void:
	_set_bits(total)


# --- P2 keyboard navigation ---

func _rebuild_p2_interactables() -> void:
	_p2_highlight_nodes.clear()
	_p2_buttons.clear()
	for card: Node in _cards_row.get_children():
		var panel := card as PanelContainer
		if not panel:
			continue
		var vbox := panel.get_child(0) as VBoxContainer
		if not vbox:
			continue
		var btn := vbox.get_child(3) as Button
		if btn:
			_p2_highlight_nodes.append(panel)
			_p2_buttons.append(btn)
	_p2_highlight_nodes.append(_reroll_button)
	_p2_buttons.append(_reroll_button)
	_p2_highlight_nodes.append(_repair_button)
	_p2_buttons.append(_repair_button)
	_p2_highlight_nodes.append(_continue_button)
	_p2_buttons.append(_continue_button)
	_p2_highlight_nodes.append(_abandon_button)
	_p2_buttons.append(_abandon_button)
	_p2_cursor = clampi(_p2_cursor, 0, _p2_highlight_nodes.size() - 1)
	_update_p2_highlight()


func _p2_move(dir: int) -> void:
	if _p2_highlight_nodes.is_empty():
		return
	_p2_cursor = clampi(_p2_cursor + dir, 0, _p2_highlight_nodes.size() - 1)
	_update_p2_highlight()


func _p2_confirm() -> void:
	if _p2_cursor >= _p2_buttons.size():
		return
	var btn := _p2_buttons[_p2_cursor]
	if btn and not btn.disabled:
		btn.pressed.emit()


func _update_p2_highlight() -> void:
	for i: int in _p2_highlight_nodes.size():
		_p2_highlight_nodes[i].modulate = Color(1.0, 0.6, 0.1, 1.0) if i == _p2_cursor else Color(1, 1, 1, 1)
