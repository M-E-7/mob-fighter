extends CanvasLayer
class_name MusicVisualizerHUD

const _BAR_HEIGHT := 80.0
const _BAR_WIDTH := 36.0
const _BAR_GAP := 12.0
const _BEAT_DECAY := 0.18
const _PEAK_HOLD_TIME := 1.2
const _PEAK_DECAY_RATE := 0.6

const _COLOR_BASS := Color(0.0, 1.0, 0.9)
const _COLOR_MID := Color(0.55, 0.4, 1.0)
const _COLOR_TREBLE := Color(1.0, 0.6, 0.0)
const _COLOR_ONSET := Color(1.0, 0.9, 0.2)
const _COLOR_BAR_BG := Color(0.08, 0.08, 0.12)
const _COLOR_BEAT_ON := Color(1.0, 1.0, 0.4)
const _COLOR_BEAT_OFF := Color(0.15, 0.15, 0.18)
const _COLOR_COOLDOWN_READY := Color(0.0, 0.8, 0.4)
const _COLOR_COOLDOWN_BUSY := Color(0.9, 0.4, 0.1)
const _COLOR_PANEL_BG := Color(0.05, 0.05, 0.08, 0.92)
const _COLOR_BORDER := Color(0.2, 0.2, 0.35)
const _COLOR_TEXT := Color(0.75, 0.75, 0.85)
const _COLOR_RAW := Color(0.5, 0.5, 0.6)

var _bass_fill: ColorRect
var _mid_fill: ColorRect
var _treble_fill: ColorRect
var _onset_fill: ColorRect
var _bass_label: Label
var _mid_label: Label
var _treble_label: Label
var _onset_label: Label
var _bass_raw_label: Label
var _mid_raw_label: Label
var _treble_raw_label: Label
var _onset_thr_label: Label
var _bass_peak: ColorRect
var _mid_peak: ColorRect
var _treble_peak: ColorRect
var _onset_peak: ColorRect
var _beat_indicator: ColorRect
var _cooldown_fill: ColorRect
var _cooldown_container: Control
var _song_label: Label
var _timeline_bar: Control
var _timeline_fill: ColorRect
var _time_label: Label

var _threshold_val_label: Label
var _cooldown_val_label: Label
var _smoothing_val_label: Label
var _db_floor_val_label: Label
var _spike_str_val_label: Label
var _spike_dec_val_label: Label
var _wall_glow_val_label: Label
var _wall_pulse_val_label: Label

var _beat_flash: float = 0.0
var _timeline_dragging: bool = false
var _peak_bass: float = 0.0
var _peak_mid: float = 0.0
var _peak_treble: float = 0.0
var _peak_onset: float = 0.0
var _peak_hold_bass: float = 0.0
var _peak_hold_mid: float = 0.0
var _peak_hold_treble: float = 0.0
var _peak_hold_onset: float = 0.0
var _root: Control


func _ready() -> void:
	layer = 11
	_build_ui()
	EventBus.beat_detected.connect(_on_beat_detected)
	MusicManager.song_changed.connect(_on_song_changed)


func _process(delta: float) -> void:
	_root.visible = GameConfig.show_music_visualizer
	if not GameConfig.show_music_visualizer:
		return

	_update_bar(_bass_fill, MusicManager.bass)
	_update_bar(_mid_fill, MusicManager.mid)
	_update_bar(_treble_fill, MusicManager.treble)

	var onset_denom := MusicManager.onset_threshold * 2.0
	var onset_normalized := clampf(MusicManager.onset_energy / onset_denom, 0.0, 1.0) if onset_denom > 0.0 else 1.0
	_update_bar(_onset_fill, onset_normalized)

	_bass_label.text = "%.2f" % MusicManager.bass
	_mid_label.text = "%.2f" % MusicManager.mid
	_treble_label.text = "%.2f" % MusicManager.treble
	_onset_label.text = "%.2f" % MusicManager.onset_energy

	_bass_raw_label.text = "r:%.2f" % MusicManager.raw_bass
	_mid_raw_label.text = "r:%.2f" % MusicManager.raw_mid
	_treble_raw_label.text = "r:%.2f" % MusicManager.raw_treble
	_onset_thr_label.text = "thr:%.2f" % MusicManager.onset_threshold

	_update_peak(delta, MusicManager.bass, _bass_peak, _peak_bass, _peak_hold_bass)
	_update_peak(delta, MusicManager.mid, _mid_peak, _peak_mid, _peak_hold_mid)
	_update_peak(delta, MusicManager.treble, _treble_peak, _peak_treble, _peak_hold_treble)
	_update_peak(delta, onset_normalized, _onset_peak, _peak_onset, _peak_hold_onset)

	_beat_flash = maxf(0.0, _beat_flash - delta / _BEAT_DECAY)
	_beat_indicator.color = _COLOR_BEAT_OFF.lerp(_COLOR_BEAT_ON, _beat_flash)
	_onset_fill.color = _COLOR_ONSET.lerp(_COLOR_BEAT_ON, _beat_flash)

	var fraction := MusicManager.beat_cooldown_remaining / MusicManager.beat_cooldown if MusicManager.beat_cooldown > 0.0 else 0.0
	var container_w: float = _cooldown_container.size.x
	_cooldown_fill.size.x = container_w * fraction
	_cooldown_fill.color = _COLOR_COOLDOWN_READY.lerp(_COLOR_COOLDOWN_BUSY, fraction)

	_threshold_val_label.text = "%.2f" % MusicManager.onset_threshold
	_cooldown_val_label.text = "%.2f" % MusicManager.beat_cooldown
	_smoothing_val_label.text = "%.2f" % MusicManager.smoothing
	_db_floor_val_label.text = "%.0f" % MusicManager.db_floor

	var lvc := get_tree().get_first_node_in_group("level_visuals_controller") as LevelVisualsController
	if lvc:
		_wall_glow_val_label.text = "%.2f" % lvc.wall_glow_peak
		_wall_pulse_val_label.text = "%.2f" % lvc.wall_pulse_amount

	var mvc := get_tree().get_first_node_in_group("music_visuals_component") as MusicVisualsComponent
	if mvc:
		_spike_str_val_label.text = "%.1f" % mvc.beat_spike_strength
		_spike_dec_val_label.text = "%.2f" % mvc.beat_spike_decay

	var duration := MusicManager.get_duration()
	var position := MusicManager.get_position()
	var timeline_fraction := clampf(position / duration, 0.0, 1.0) if duration > 0.0 else 0.0
	_timeline_fill.size.x = _timeline_bar.size.x * timeline_fraction
	_time_label.text = "%s / %s" % [_format_time(position), _format_time(duration)]


func _on_beat_detected() -> void:
	_beat_flash = 1.0


func _on_song_changed(song_name: String) -> void:
	_song_label.text = song_name


func _on_timeline_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_timeline_dragging = mb.pressed
			if _timeline_dragging:
				_seek_to_mouse(mb.position.x)
	elif event is InputEventMouseMotion and _timeline_dragging:
		_seek_to_mouse((event as InputEventMouseMotion).position.x)


func _seek_to_mouse(local_x: float) -> void:
	var ratio := clampf(local_x / _timeline_bar.size.x, 0.0, 1.0)
	MusicManager.seek(ratio * MusicManager.get_duration())


func _format_time(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d" % [s / 60, s % 60]


func _update_bar(fill: ColorRect, value: float) -> void:
	fill.size.y = _BAR_HEIGHT * value
	fill.position.y = _BAR_HEIGHT - fill.size.y


func _update_peak(delta: float, value: float, marker: ColorRect, peak: float, hold: float) -> void:
	if value >= peak:
		peak = value
		hold = _PEAK_HOLD_TIME
	elif hold > 0.0:
		hold -= delta
	else:
		peak = maxf(0.0, peak - _PEAK_DECAY_RATE * delta)

	marker.position.y = _BAR_HEIGHT - _BAR_HEIGHT * peak - 2.0

	# Write back — GDScript passes floats by value, so update the actual members
	if marker == _bass_peak:
		_peak_bass = peak
		_peak_hold_bass = hold
	elif marker == _mid_peak:
		_peak_mid = peak
		_peak_hold_mid = hold
	elif marker == _treble_peak:
		_peak_treble = peak
		_peak_hold_treble = hold
	else:
		_peak_onset = peak
		_peak_hold_onset = hold


func _build_ui() -> void:
	_root = Control.new()
	_root.anchor_right = 1.0
	_root.anchor_bottom = 1.0
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	var panel := _make_panel()
	_root.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# Song name with prev/next navigation
	var nav_row := HBoxContainer.new()
	nav_row.alignment = BoxContainer.ALIGNMENT_CENTER
	nav_row.add_theme_constant_override("separation", 6)
	vbox.add_child(nav_row)

	var prev_btn := _make_nav_button("◀")
	prev_btn.pressed.connect(MusicManager.prev_song)
	nav_row.add_child(prev_btn)

	_song_label = Label.new()
	_song_label.text = MusicManager.current_song_name()
	_song_label.add_theme_font_size_override("font_size", 11)
	_song_label.modulate = _COLOR_TEXT
	_song_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_song_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav_row.add_child(_song_label)

	var next_btn := _make_nav_button("▶")
	next_btn.pressed.connect(MusicManager.next_song)
	nav_row.add_child(next_btn)

	# Timeline scrubber
	_timeline_bar = Control.new()
	_timeline_bar.custom_minimum_size = Vector2(0, 10)
	_timeline_bar.size_flags_horizontal = Control.SIZE_FILL
	_timeline_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	_timeline_bar.gui_input.connect(_on_timeline_input)
	vbox.add_child(_timeline_bar)

	var tl_bg := ColorRect.new()
	tl_bg.color = _COLOR_BAR_BG
	tl_bg.anchor_right = 1.0
	tl_bg.anchor_bottom = 1.0
	_timeline_bar.add_child(tl_bg)

	_timeline_fill = ColorRect.new()
	_timeline_fill.color = _COLOR_BASS
	_timeline_fill.size = Vector2(0.0, 10.0)
	_timeline_bar.add_child(_timeline_fill)

	_time_label = Label.new()
	_time_label.text = "0:00 / 0:00"
	_time_label.add_theme_font_size_override("font_size", 10)
	_time_label.modulate = _COLOR_RAW
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_time_label)

	# Beat indicator row
	var beat_row := HBoxContainer.new()
	beat_row.alignment = BoxContainer.ALIGNMENT_CENTER
	beat_row.add_theme_constant_override("separation", 6)
	vbox.add_child(beat_row)

	var beat_lbl := Label.new()
	beat_lbl.text = "BEAT"
	beat_lbl.add_theme_font_size_override("font_size", 11)
	beat_lbl.modulate = _COLOR_TEXT
	beat_row.add_child(beat_lbl)

	_beat_indicator = ColorRect.new()
	_beat_indicator.custom_minimum_size = Vector2(14, 14)
	_beat_indicator.color = _COLOR_BEAT_OFF
	beat_row.add_child(_beat_indicator)

	# Cooldown bar
	var cd_label := Label.new()
	cd_label.text = "COOLDOWN"
	cd_label.add_theme_font_size_override("font_size", 10)
	cd_label.modulate = _COLOR_TEXT
	cd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(cd_label)

	_cooldown_container = Control.new()
	_cooldown_container.custom_minimum_size = Vector2(0, 8)
	_cooldown_container.size_flags_horizontal = Control.SIZE_FILL
	vbox.add_child(_cooldown_container)

	var cd_bg := ColorRect.new()
	cd_bg.color = _COLOR_BAR_BG
	cd_bg.anchor_right = 1.0
	cd_bg.anchor_bottom = 1.0
	_cooldown_container.add_child(cd_bg)

	_cooldown_fill = ColorRect.new()
	_cooldown_fill.color = _COLOR_COOLDOWN_READY
	_cooldown_fill.size = Vector2(0.0, 8.0)
	_cooldown_container.add_child(_cooldown_fill)

	# Bars
	var bars_row := HBoxContainer.new()
	bars_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bars_row.add_theme_constant_override("separation", _BAR_GAP)
	vbox.add_child(bars_row)

	var bass_col := _make_bar_column("BASS", _COLOR_BASS)
	_bass_fill = bass_col[0]
	_bass_label = bass_col[1]
	_bass_raw_label = bass_col[2]
	_bass_peak = bass_col[3]
	bars_row.add_child(bass_col[4])

	var mid_col := _make_bar_column("MID", _COLOR_MID)
	_mid_fill = mid_col[0]
	_mid_label = mid_col[1]
	_mid_raw_label = mid_col[2]
	_mid_peak = mid_col[3]
	bars_row.add_child(mid_col[4])

	var treble_col := _make_bar_column("TREBLE", _COLOR_TREBLE)
	_treble_fill = treble_col[0]
	_treble_label = treble_col[1]
	_treble_raw_label = treble_col[2]
	_treble_peak = treble_col[3]
	bars_row.add_child(treble_col[4])

	var onset_col := _make_onset_column()
	_onset_fill = onset_col[0]
	_onset_label = onset_col[1]
	_onset_thr_label = onset_col[2]
	_onset_peak = onset_col[3]
	bars_row.add_child(onset_col[4])

	# Separator
	var sep := ColorRect.new()
	sep.color = _COLOR_BORDER
	sep.custom_minimum_size = Vector2(0, 1)
	sep.size_flags_horizontal = Control.SIZE_FILL
	vbox.add_child(sep)

	# Tuning sliders
	var tuning_lbl := Label.new()
	tuning_lbl.text = "TUNING"
	tuning_lbl.add_theme_font_size_override("font_size", 10)
	tuning_lbl.modulate = _COLOR_RAW
	tuning_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(tuning_lbl)

	var thr_row := _make_slider_row("ONSET THR", 0.0, 1.0, 0.01, MusicManager.onset_threshold)
	_threshold_val_label = thr_row[1]
	(thr_row[0] as HSlider).value_changed.connect(func(v: float) -> void: MusicManager.onset_threshold = v)
	vbox.add_child(thr_row[2])

	var cd_row := _make_slider_row("COOLDOWN", 0.0, 2.0, 0.05, MusicManager.beat_cooldown)
	_cooldown_val_label = cd_row[1]
	(cd_row[0] as HSlider).value_changed.connect(func(v: float) -> void: MusicManager.beat_cooldown = v)
	vbox.add_child(cd_row[2])

	var sm_row := _make_slider_row("SMOOTHING", 0.01, 0.5, 0.01, MusicManager.smoothing)
	_smoothing_val_label = sm_row[1]
	(sm_row[0] as HSlider).value_changed.connect(func(v: float) -> void: MusicManager.smoothing = v)
	vbox.add_child(sm_row[2])

	var db_row := _make_slider_row("DB FLOOR", -80.0, -20.0, 1.0, MusicManager.db_floor)
	_db_floor_val_label = db_row[1]
	(db_row[0] as HSlider).value_changed.connect(func(v: float) -> void: MusicManager.db_floor = v)
	vbox.add_child(db_row[2])

	var spike_str_row := _make_slider_row("SPIKE STR", 0.0, 5.0, 0.1, 3.0)
	_spike_str_val_label = spike_str_row[1]
	(spike_str_row[0] as HSlider).value_changed.connect(func(v: float) -> void:
		for node: MusicVisualsComponent in get_tree().get_nodes_in_group("music_visuals_component"):
			node.beat_spike_strength = v
	)
	vbox.add_child(spike_str_row[2])

	var spike_dec_row := _make_slider_row("SPIKE DEC", 0.05, 2.0, 0.05, 0.25)
	_spike_dec_val_label = spike_dec_row[1]
	(spike_dec_row[0] as HSlider).value_changed.connect(func(v: float) -> void:
		for node: MusicVisualsComponent in get_tree().get_nodes_in_group("music_visuals_component"):
			node.beat_spike_decay = v
	)
	vbox.add_child(spike_dec_row[2])

	var wall_glow_row := _make_slider_row("WALL GLOW", 0.0, 1.0, 0.01, 0.80)
	_wall_glow_val_label = wall_glow_row[1]
	(wall_glow_row[0] as HSlider).value_changed.connect(func(v: float) -> void:
		var lvc := get_tree().get_first_node_in_group("level_visuals_controller") as LevelVisualsController
		if lvc:
			lvc.wall_glow_peak = v
	)
	vbox.add_child(wall_glow_row[2])

	var wall_pulse_row := _make_slider_row("WALL PULSE", 0.0, 1.0, 0.01, 0.40)
	_wall_pulse_val_label = wall_pulse_row[1]
	(wall_pulse_row[0] as HSlider).value_changed.connect(func(v: float) -> void:
		var lvc := get_tree().get_first_node_in_group("level_visuals_controller") as LevelVisualsController
		if lvc:
			lvc.wall_pulse_amount = v
	)
	vbox.add_child(wall_pulse_row[2])


# Returns [fill, value_label, raw_label, peak_marker, column_vbox]
func _make_bar_column(band_name: String, bar_color: Color) -> Array:
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_END
	col.add_theme_constant_override("separation", 3)

	var bar_container := Control.new()
	bar_container.custom_minimum_size = Vector2(_BAR_WIDTH, _BAR_HEIGHT)
	col.add_child(bar_container)

	var bg := ColorRect.new()
	bg.color = _COLOR_BAR_BG
	bg.size = Vector2(_BAR_WIDTH, _BAR_HEIGHT)
	bar_container.add_child(bg)

	var fill := ColorRect.new()
	fill.color = bar_color
	fill.size = Vector2(_BAR_WIDTH, 0.0)
	fill.position = Vector2(0.0, _BAR_HEIGHT)
	bar_container.add_child(fill)

	var peak := ColorRect.new()
	peak.color = Color.WHITE
	peak.size = Vector2(_BAR_WIDTH, 2.0)
	peak.position = Vector2(0.0, _BAR_HEIGHT)
	bar_container.add_child(peak)

	var val_label := Label.new()
	val_label.text = "0.00"
	val_label.add_theme_font_size_override("font_size", 11)
	val_label.modulate = _COLOR_TEXT
	val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val_label.custom_minimum_size = Vector2(_BAR_WIDTH, 0)
	col.add_child(val_label)

	var raw_label := Label.new()
	raw_label.text = "r:0.00"
	raw_label.add_theme_font_size_override("font_size", 10)
	raw_label.modulate = _COLOR_RAW
	raw_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	raw_label.custom_minimum_size = Vector2(_BAR_WIDTH, 0)
	col.add_child(raw_label)

	var name_label := Label.new()
	name_label.text = band_name
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.modulate = bar_color
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.custom_minimum_size = Vector2(_BAR_WIDTH, 0)
	col.add_child(name_label)

	return [fill, val_label, raw_label, peak, col]


# Returns [fill, value_label, thr_label, peak_marker, column_vbox]
# Bar height = onset_energy / (onset_threshold * 2) so threshold sits at exactly 50%.
func _make_onset_column() -> Array:
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_END
	col.add_theme_constant_override("separation", 3)

	var bar_container := Control.new()
	bar_container.custom_minimum_size = Vector2(_BAR_WIDTH, _BAR_HEIGHT)
	col.add_child(bar_container)

	var bg := ColorRect.new()
	bg.color = _COLOR_BAR_BG
	bg.size = Vector2(_BAR_WIDTH, _BAR_HEIGHT)
	bar_container.add_child(bg)

	var fill := ColorRect.new()
	fill.color = _COLOR_ONSET
	fill.size = Vector2(_BAR_WIDTH, 0.0)
	fill.position = Vector2(0.0, _BAR_HEIGHT)
	bar_container.add_child(fill)

	# Threshold line at 50% — this is where onset_energy == onset_threshold
	var thr_line := ColorRect.new()
	thr_line.color = Color(1.0, 1.0, 1.0, 0.55)
	thr_line.size = Vector2(_BAR_WIDTH, 2.0)
	thr_line.position = Vector2(0.0, _BAR_HEIGHT * 0.5 - 1.0)
	bar_container.add_child(thr_line)

	var peak := ColorRect.new()
	peak.color = Color.WHITE
	peak.size = Vector2(_BAR_WIDTH, 2.0)
	peak.position = Vector2(0.0, _BAR_HEIGHT)
	bar_container.add_child(peak)

	var val_label := Label.new()
	val_label.text = "0.00"
	val_label.add_theme_font_size_override("font_size", 11)
	val_label.modulate = _COLOR_TEXT
	val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val_label.custom_minimum_size = Vector2(_BAR_WIDTH, 0)
	col.add_child(val_label)

	var thr_label := Label.new()
	thr_label.text = "thr:0.00"
	thr_label.add_theme_font_size_override("font_size", 10)
	thr_label.modulate = _COLOR_RAW
	thr_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	thr_label.custom_minimum_size = Vector2(_BAR_WIDTH, 0)
	col.add_child(thr_label)

	var name_label := Label.new()
	name_label.text = "ONSET"
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.modulate = _COLOR_ONSET
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.custom_minimum_size = Vector2(_BAR_WIDTH, 0)
	col.add_child(name_label)

	return [fill, val_label, thr_label, peak, col]


# Returns [HSlider, value_label, row_container]
func _make_slider_row(label_text: String, min_v: float, max_v: float, step: float, init_v: float) -> Array:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.size_flags_horizontal = Control.SIZE_FILL

	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.modulate = _COLOR_TEXT
	lbl.custom_minimum_size = Vector2(72, 0)
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step
	slider.value = init_v
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(0, 16)
	slider.focus_mode = Control.FOCUS_NONE
	row.add_child(slider)

	var val_lbl := Label.new()
	val_lbl.text = "%.2f" % init_v
	val_lbl.add_theme_font_size_override("font_size", 10)
	val_lbl.modulate = _COLOR_ONSET
	val_lbl.custom_minimum_size = Vector2(32, 0)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(val_lbl)

	return [slider, val_lbl, row]


func _make_nav_button(icon: String) -> Button:
	var btn := Button.new()
	btn.text = icon
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", _COLOR_TEXT)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", _COLOR_BEAT_ON)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.18)
	style.set_corner_radius_all(4)
	style.content_margin_left = 6.0
	style.content_margin_right = 6.0
	style.content_margin_top = 2.0
	style.content_margin_bottom = 2.0
	btn.add_theme_stylebox_override("normal", style)
	var hover_style := style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.20, 0.20, 0.28)
	btn.add_theme_stylebox_override("hover", hover_style)
	return btn


func _make_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.offset_left = -8.0
	panel.offset_top = 8.0
	panel.offset_right = -8.0
	panel.offset_bottom = 8.0

	var style := StyleBoxFlat.new()
	style.bg_color = _COLOR_PANEL_BG
	style.border_color = _COLOR_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	panel.add_theme_stylebox_override("panel", style)

	return panel
