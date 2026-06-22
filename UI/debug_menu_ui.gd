extends CanvasLayer
class_name DebugMenuUI

signal close_requested
signal force_win_requested
signal force_game_over_requested
signal reload_sector_requested(sector: int)

var _info_label: Label
var _bits_spin: SpinBox
var _sector_spin: SpinBox
var _health_spins: Array[SpinBox] = []
var _god_checks: Array[CheckButton] = []
var _obj_target_spin: SpinBox
var _obj_progress_spin: SpinBox
var _refreshing: bool = false

const _COLOR_ACCENT := Color(0.0, 1.0, 0.9)
const _COLOR_DIM := Color(0.55, 0.55, 0.6)
const _COLOR_WARN := Color(1.0, 0.45, 0.1)
const _COLOR_BG := Color(0.05, 0.05, 0.08, 0.97)
const _COLOR_SECTION := Color(0.45, 0.45, 0.65)

@onready var _content: VBoxContainer = $Panel/ScrollContainer/Content


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_panel_style()
	_build_ui()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if _is_debug_toggle(event) or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_requested.emit()


func _process(_d: float) -> void:
	if not visible:
		return
	_refresh_info()


func refresh() -> void:
	_refreshing = true
	if is_instance_valid(_bits_spin):
		_bits_spin.value = RunState.currency
	if is_instance_valid(_sector_spin):
		_sector_spin.value = max(RunState.current_level, 1)
	var players := get_tree().get_nodes_in_group("player")
	for idx in _health_spins.size():
		if idx >= players.size():
			break
		var p := players[idx] as LivingEntity
		if is_instance_valid(p) and p.healthComponent:
			_health_spins[idx].max_value = p.healthComponent.max_health
			_health_spins[idx].value = p.healthComponent.current_health
	for idx in _god_checks.size():
		if idx >= players.size():
			break
		var p := players[idx] as LivingEntity
		if is_instance_valid(p) and p.healthComponent:
			_god_checks[idx].button_pressed = p.healthComponent.invincible
	var obj := get_tree().get_first_node_in_group("level_objective") as LevelObjectiveComponent
	if is_instance_valid(obj):
		if is_instance_valid(_obj_target_spin):
			_obj_target_spin.value = obj.get_target()
		if is_instance_valid(_obj_progress_spin):
			_obj_progress_spin.value = obj.get_progress()
	_refreshing = false


func _build_ui() -> void:
	var title := Label.new()
	title.text = "  DEBUG MENU"
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = _COLOR_ACCENT
	_content.add_child(title)

	# Info
	_add_section("INFO")
	_info_label = Label.new()
	_info_label.add_theme_font_size_override("font_size", 13)
	_info_label.modulate = _COLOR_DIM
	_info_label.text = "..."
	_content.add_child(_info_label)

	# Run
	_add_section("RUN")
	_bits_spin = _add_spin_row("Bits", RunState.currency, 999999.0)
	_bits_spin.value_changed.connect(_on_bits_changed)
	var bits_row := HBoxContainer.new()
	bits_row.add_theme_constant_override("separation", 8)
	_content.add_child(bits_row)
	var btn100 := _make_button("+100", _COLOR_ACCENT, Color(0.0, 0.1, 0.12))
	btn100.pressed.connect(_on_grant_bits.bind(100))
	bits_row.add_child(btn100)
	var btn1000 := _make_button("+1000", _COLOR_ACCENT, Color(0.0, 0.1, 0.12))
	btn1000.pressed.connect(_on_grant_bits.bind(1000))
	bits_row.add_child(btn1000)

	_sector_spin = _add_spin_row("Jump to Sector", max(float(RunState.current_level), 1.0), float(RunState.MAX_LEVELS))
	_sector_spin.min_value = 1.0
	var sector_btn_row := HBoxContainer.new()
	sector_btn_row.add_theme_constant_override("separation", 8)
	_content.add_child(sector_btn_row)
	var sector_btn := _make_button("Reload as Sector N", _COLOR_WARN, Color(0.12, 0.04, 0.0))
	sector_btn.pressed.connect(func() -> void:
		reload_sector_requested.emit(int(_sector_spin.value)))
	sector_btn_row.add_child(sector_btn)

	# Players
	_add_section("PLAYERS")
	_health_spins.clear()
	_god_checks.clear()
	var players := get_tree().get_nodes_in_group("player")
	for idx in players.size():
		var p := players[idx] as LivingEntity
		if not is_instance_valid(p):
			continue
		var max_hp := p.healthComponent.max_health if p.healthComponent else 100.0
		var cur_hp := p.healthComponent.current_health if p.healthComponent else 0.0
		var spin := _add_spin_row("P%d Health" % (idx + 1), cur_hp, max_hp)
		spin.value_changed.connect(_on_health_changed.bind(idx))
		_health_spins.append(spin)
		var player_row := HBoxContainer.new()
		player_row.add_theme_constant_override("separation", 8)
		_content.add_child(player_row)
		var heal_btn := _make_button("P%d Full Heal" % (idx + 1), _COLOR_ACCENT, Color(0.0, 0.1, 0.12))
		heal_btn.pressed.connect(_on_full_heal.bind(idx))
		player_row.add_child(heal_btn)
		var god_check := CheckButton.new()
		god_check.text = "P%d God Mode" % (idx + 1)
		god_check.add_theme_font_size_override("font_size", 14)
		god_check.add_theme_color_override("font_color", _COLOR_WARN)
		god_check.add_theme_color_override("font_pressed_color", _COLOR_WARN)
		god_check.toggled.connect(_on_god_toggled.bind(idx))
		player_row.add_child(god_check)
		_god_checks.append(god_check)

	# Objective
	_add_section("OBJECTIVE")
	var obj := get_tree().get_first_node_in_group("level_objective") as LevelObjectiveComponent
	var init_target := float(obj.get_target()) if is_instance_valid(obj) else 20.0
	var init_progress := float(obj.get_progress()) if is_instance_valid(obj) else 0.0
	_obj_target_spin = _add_spin_row("Requirement", init_target, 9999.0)
	_obj_target_spin.min_value = 1.0
	_obj_target_spin.value_changed.connect(_on_obj_target_changed)
	_obj_progress_spin = _add_spin_row("Progress", init_progress, 9999.0)
	_obj_progress_spin.value_changed.connect(_on_obj_progress_changed)
	_add_button("Complete Objective Now", _COLOR_ACCENT, Color(0.0, 0.1, 0.12), func() -> void:
		var o := get_tree().get_first_node_in_group("level_objective") as LevelObjectiveComponent
		if is_instance_valid(o):
			o.complete_now())

	# Actions
	_add_section("ACTIONS")
	_add_button("Kill All Enemies", _COLOR_WARN, Color(0.12, 0.04, 0.0), func() -> void:
		for e in get_tree().get_nodes_in_group("enemy"):
			var ent := e as LivingEntity
			if is_instance_valid(ent) and ent.healthComponent:
				ent.healthComponent.take_damage(1e9))
	_add_button("Force Win", _COLOR_ACCENT, Color(0.0, 0.1, 0.12), func() -> void:
		force_win_requested.emit())
	_add_button("Force Game Over", _COLOR_WARN, Color(0.12, 0.04, 0.0), func() -> void:
		force_game_over_requested.emit())

	# Close
	var bottom_spacer := Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 8)
	_content.add_child(bottom_spacer)
	_add_button("CLOSE   [Alt / Esc]", _COLOR_DIM, Color(0.07, 0.07, 0.12), func() -> void:
		close_requested.emit())


func _on_bits_changed(v: float) -> void:
	if _refreshing:
		return
	RunState.currency = int(v)
	EventBus.currency_changed.emit(RunState.currency)


func _on_grant_bits(amount: int) -> void:
	RunState.currency += amount
	EventBus.currency_changed.emit(RunState.currency)
	if is_instance_valid(_bits_spin):
		_refreshing = true
		_bits_spin.value = RunState.currency
		_refreshing = false


func _on_health_changed(v: float, idx: int) -> void:
	if _refreshing:
		return
	var players := get_tree().get_nodes_in_group("player")
	if idx >= players.size():
		return
	var p := players[idx] as LivingEntity
	if not is_instance_valid(p) or not p.healthComponent:
		return
	p.healthComponent.current_health = v
	EventBus.health_changed.emit(p, v, p.healthComponent.max_health)


func _on_full_heal(idx: int) -> void:
	var players := get_tree().get_nodes_in_group("player")
	if idx >= players.size():
		return
	var p := players[idx] as LivingEntity
	if not is_instance_valid(p) or not p.healthComponent:
		return
	p.healthComponent.heal(p.healthComponent.max_health)


func _on_god_toggled(on: bool, idx: int) -> void:
	if _refreshing:
		return
	var players := get_tree().get_nodes_in_group("player")
	if idx >= players.size():
		return
	var p := players[idx] as LivingEntity
	if not is_instance_valid(p) or not p.healthComponent:
		return
	p.healthComponent.invincible = on


func _on_obj_target_changed(v: float) -> void:
	if _refreshing:
		return
	var obj := get_tree().get_first_node_in_group("level_objective") as LevelObjectiveComponent
	if is_instance_valid(obj):
		obj.set_target(int(v))


func _on_obj_progress_changed(v: float) -> void:
	if _refreshing:
		return
	var obj := get_tree().get_first_node_in_group("level_objective") as LevelObjectiveComponent
	if is_instance_valid(obj):
		obj.set_progress(int(v))


func _refresh_info() -> void:
	if not is_instance_valid(_info_label):
		return
	var enemy_count := get_tree().get_nodes_in_group("enemy").size()
	var players := get_tree().get_nodes_in_group("player")
	var pos_str := "N/A"
	if players.size() > 0:
		var p1 := players[0] as Node2D
		if is_instance_valid(p1):
			pos_str = "(%d, %d)" % [int(p1.global_position.x), int(p1.global_position.y)]
	_info_label.text = "FPS: %d  |  Enemies: %d  |  Sector: %d  |  P1: %s" % [
		Engine.get_frames_per_second(),
		enemy_count,
		RunState.current_level,
		pos_str,
	]


func _is_debug_toggle(event: InputEvent) -> bool:
	if event.is_action_pressed("toggle_debug_menu"):
		return true
	if event is InputEventKey:
		var key := event as InputEventKey
		return key.pressed and not key.echo and key.keycode == KEY_ALT
	return false


func _apply_panel_style() -> void:
	var panel := $Panel as PanelContainer
	var style := StyleBoxFlat.new()
	style.bg_color = _COLOR_BG
	style.border_color = Color(0.2, 0.6, 0.7, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	panel.add_theme_stylebox_override("panel", style)


func _add_section(title: String) -> void:
	var sep := HSeparator.new()
	_content.add_child(sep)
	var lbl := Label.new()
	lbl.text = title
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.modulate = _COLOR_SECTION
	_content.add_child(lbl)


func _add_spin_row(label_text: String, current: float, max_val: float) -> SpinBox:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_content.add_child(row)
	var lbl := Label.new()
	lbl.text = label_text + ":"
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.modulate = _COLOR_DIM
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)
	var spin := SpinBox.new()
	spin.min_value = 0.0
	spin.max_value = max_val
	spin.step = 1.0
	spin.value = current
	spin.custom_minimum_size = Vector2(130, 0)
	row.add_child(spin)
	return spin


func _add_button(label_text: String, border: Color, bg: Color, on_pressed: Callable) -> Button:
	var btn := _make_button(label_text, border, bg)
	btn.pressed.connect(on_pressed)
	_content.add_child(btn)
	return btn


func _make_button(label_text: String, border: Color, bg: Color) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_style_button(btn, border, bg)
	return btn


func _style_button(btn: Button, border: Color, bg: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.border_color = border
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(4)
	normal.content_margin_left = 24.0
	normal.content_margin_right = 24.0
	normal.content_margin_top = 8.0
	normal.content_margin_bottom = 8.0
	btn.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = bg.lightened(0.1)
	hover.border_color = border.lightened(0.2)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_color_override("font_color", border)
	btn.add_theme_color_override("font_hover_color", border.lightened(0.25))
	btn.add_theme_font_size_override("font_size", 14)
