extends Control
class_name AdvancedSettings

const _SETTINGS_SCENE := "res://Levels/Settings/Settings.tscn"

const _COLOR_ACCENT := Color(0.0, 1.0, 0.9)
const _COLOR_DIM := Color(0.45, 0.45, 0.5)
const _COLOR_GROUP := Color(0.0, 0.85, 0.75)
const _COLOR_BG := Color(0.047, 0.047, 0.07, 1.0)

@onready var _content_vbox: VBoxContainer = $RootVBox/ScrollContainer/ContentVBox
@onready var _search_bar: LineEdit = $RootVBox/HeaderHBox/SearchBar
@onready var _back_button: Button = $RootVBox/BackButton

# Maps each row node to its group header node for search filtering
var _row_to_group: Dictionary = {}
# All property rows in order
var _rows: Array[Control] = []
# Group header nodes keyed by group name
var _group_headers: Dictionary = {}


func _ready() -> void:
	_apply_theme()
	_build_ui()
	_search_bar.text_changed.connect(_on_search_changed)
	_back_button.pressed.connect(_on_back_pressed)


func _build_ui() -> void:
	var current_group := ""
	var current_header: Label = null

	for def in AdvancedConfig.PROPERTY_DEFS:
		var group: String = def["group"]
		var cls: String = def["class"]
		var prop: String = def["name"]
		var prop_type: int = def["type"]

		if group != current_group:
			current_group = group
			current_header = _make_group_header(group)
			_content_vbox.add_child(current_header)
			_group_headers[group] = current_header

		var row := _make_row(def, cls, prop, prop_type)
		_content_vbox.add_child(row)
		_rows.append(row)
		_row_to_group[row] = current_header


func _make_group_header(group: String) -> Label:
	var lbl := Label.new()
	lbl.text = group.to_upper()
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.modulate = _COLOR_GROUP
	# Extra top margin before each group
	lbl.custom_minimum_size = Vector2(0, 32)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	return lbl


func _make_row(def: Dictionary, cls: String, prop: String, prop_type: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)

	var label := Label.new()
	label.text = prop.replace("_", " ").capitalize()
	label.custom_minimum_size = Vector2(260, 0)
	label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	label.add_theme_font_size_override("font_size", 17)
	label.modulate = Color(0.85, 0.85, 0.9)
	row.add_child(label)

	var current_val: Variant = AdvancedConfig.get_override(cls, prop)

	match prop_type:
		TYPE_FLOAT:
			_add_float_widget(row, def, cls, prop, float(current_val))
		TYPE_INT:
			_add_int_widget(row, def, cls, prop, int(current_val))
		TYPE_BOOL:
			_add_bool_widget(row, cls, prop, bool(current_val))
		TYPE_COLOR:
			_add_color_widget(row, cls, prop, current_val as Color)

	return row


func _add_float_widget(row: HBoxContainer, def: Dictionary, cls: String, prop: String, val: float) -> void:
	var slider := HSlider.new()
	slider.min_value = def.get("min", 0.0)
	slider.max_value = def.get("max", 1.0)
	slider.step = def.get("step", 0.01)
	slider.value = val
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(200, 0)

	var spin := SpinBox.new()
	spin.min_value = slider.min_value
	spin.max_value = slider.max_value
	spin.step = slider.step
	spin.value = val
	spin.custom_minimum_size = Vector2(110, 0)
	spin.allow_greater = false
	spin.allow_lesser = false

	# Keep slider and spinbox in sync
	slider.value_changed.connect(func(v: float) -> void:
		spin.set_value_no_signal(v)
		AdvancedConfig.set_override(cls, prop, v)
	)
	spin.value_changed.connect(func(v: float) -> void:
		slider.set_value_no_signal(v)
		AdvancedConfig.set_override(cls, prop, v)
	)

	row.add_child(slider)
	row.add_child(spin)


func _add_int_widget(row: HBoxContainer, def: Dictionary, cls: String, prop: String, val: int) -> void:
	var spin := SpinBox.new()
	spin.min_value = def.get("min", 0)
	spin.max_value = def.get("max", 100)
	spin.step = def.get("step", 1)
	spin.value = val
	spin.custom_minimum_size = Vector2(120, 0)
	spin.allow_greater = false
	spin.allow_lesser = false
	spin.value_changed.connect(func(v: float) -> void:
		AdvancedConfig.set_override(cls, prop, int(v))
	)
	row.add_child(spin)


func _add_bool_widget(row: HBoxContainer, cls: String, prop: String, val: bool) -> void:
	var check := CheckBox.new()
	check.button_pressed = val
	check.toggled.connect(func(v: bool) -> void:
		AdvancedConfig.set_override(cls, prop, v)
	)
	row.add_child(check)


func _add_color_widget(row: HBoxContainer, cls: String, prop: String, val: Color) -> void:
	var picker := ColorPickerButton.new()
	picker.color = val
	picker.custom_minimum_size = Vector2(80, 32)
	picker.color_changed.connect(func(c: Color) -> void:
		AdvancedConfig.set_override(cls, prop, c)
	)
	row.add_child(picker)


func _on_search_changed(text: String) -> void:
	var query := text.to_lower().strip_edges()

	# Reset all visibility first
	for header in _group_headers.values():
		header.visible = true
	for row in _rows:
		row.visible = true

	if query.is_empty():
		return

	# Hide non-matching rows
	for row in _rows:
		var label := row.get_child(0) as Label
		if not label:
			continue
		var prop_text := label.text.to_lower()
		var header := _row_to_group.get(row) as Label
		var group_text := (header.text.to_lower() if header else "")
		row.visible = query in prop_text or query in group_text

	# Hide group headers whose all rows are hidden
	for group_name in _group_headers:
		var header := _group_headers[group_name] as Label
		var any_visible := false
		for row in _rows:
			if _row_to_group.get(row) == header and row.visible:
				any_visible = true
				break
		header.visible = any_visible


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(_SETTINGS_SCENE)


func _apply_theme() -> void:
	$RootVBox/HeaderHBox/Title.add_theme_font_size_override("font_size", 52)
	$RootVBox/HeaderHBox/Title.modulate = _COLOR_ACCENT

	var search := _search_bar
	search.placeholder_text = "Search…"
	search.custom_minimum_size = Vector2(280, 0)
	search.add_theme_font_size_override("font_size", 18)

	var scroll_style := StyleBoxFlat.new()
	scroll_style.bg_color = Color(0.055, 0.055, 0.08)
	scroll_style.border_color = Color(0.15, 0.15, 0.25)
	scroll_style.set_border_width_all(1)
	scroll_style.set_corner_radius_all(6)
	scroll_style.content_margin_left = 24.0
	scroll_style.content_margin_right = 24.0
	scroll_style.content_margin_top = 16.0
	scroll_style.content_margin_bottom = 16.0
	($RootVBox/ScrollContainer as ScrollContainer).add_theme_stylebox_override("panel", scroll_style)

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
