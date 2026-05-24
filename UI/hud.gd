extends CanvasLayer
class_name HUD

class _PanelRefs:
	var panel: PanelContainer
	var health_row: Control
	var hp_bar: ProgressBar
	var hp_text: Label
	var xp_row: Control
	var xp_bar: ProgressBar
	var lv_label: Label
	var kill_row: Control
	var kill_count: Label
	var powerup_row: HFlowContainer

const _COLOR_P1 := Color(0.0, 1.0, 0.9)
const _COLOR_P2 := Color(1.0, 0.6, 0.0)
const _COLOR_BG := Color(0.05, 0.05, 0.08, 0.92)
const _MARGIN := 16.0
const _PANEL_MIN_W := 300.0
const _SCREEN_W := 1920.0
const _SCREEN_H := 1080.0
const _PANEL_Y := 880.0

const _POWERUP_ABBREVS: Dictionary = {
	"max_speed": "SPD",
	"fire_rate": "ATK",
	"bullet_damage": "DMG",
	"max_health": "HP+",
	"bullet_speed": "VEL",
}

var _player1: LivingEntity
var _player2: LivingEntity
var _kills1: int = 0
var _kills2: int = 0
var _p1: _PanelRefs
var _p2: _PanelRefs

var _survival_time: float = 0.0
var _timer_label: Label

var _warn_p1: ColorRect
var _warn_p2: ColorRect
var _warn_tween_p1: Tween
var _warn_tween_p2: Tween

var _prev_level_p1: int = 0
var _prev_level_p2: int = 0


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS

	_p1 = _build_panel(_COLOR_P1)
	add_child(_p1.panel)
	_p2 = _build_panel(_COLOR_P2)
	add_child(_p2.panel)

	_build_timer_label()
	_build_warnings()


func setup(p1: LivingEntity, p2: LivingEntity, player_count: int) -> void:
	_player1 = p1
	_player2 = p2
	_apply_settings()
	_position_panels(player_count)
	_connect_signals()
	_init_display(p1, _p1)
	if is_instance_valid(p2):
		_init_display(p2, _p2)


func get_survival_time() -> float:
	return _survival_time


func get_kills(player: int) -> int:
	return _kills1 if player == 1 else _kills2


func _process(delta: float) -> void:
	if not is_instance_valid(_player1):
		return
	_survival_time += delta
	var secs := int(_survival_time)
	_timer_label.text = "%d:%02d" % [secs / 60, secs % 60]


func _init_display(entity: LivingEntity, refs: _PanelRefs) -> void:
	if entity.healthComponent:
		_update_health(refs, entity.healthComponent.current_health, entity.healthComponent.max_health)
	var xp_comp := entity.get_node_or_null("XPComponent") as XPComponent
	if xp_comp:
		var required := xp_comp.base_xp_required * pow(2.0, float(xp_comp.current_level))
		_update_xp(refs, xp_comp.current_xp, required, xp_comp.current_level)


func _apply_settings() -> void:
	_p1.health_row.visible = GameConfig.hud_show_health
	_p2.health_row.visible = GameConfig.hud_show_health
	_p1.xp_row.visible = GameConfig.hud_show_xp
	_p2.xp_row.visible = GameConfig.hud_show_xp
	_p1.kill_row.visible = GameConfig.hud_show_kills
	_p2.kill_row.visible = GameConfig.hud_show_kills
	_p1.powerup_row.visible = GameConfig.hud_show_powerups
	_p2.powerup_row.visible = GameConfig.hud_show_powerups
	_timer_label.get_parent().visible = GameConfig.hud_show_survival_timer


func _position_panels(player_count: int) -> void:
	_p1.panel.custom_minimum_size = Vector2(_PANEL_MIN_W, 0.0)
	_p1.panel.position = Vector2(_MARGIN, _PANEL_Y)
	if player_count == 1:
		_p2.panel.hide()
		_warn_p1.size = Vector2(_SCREEN_W, _SCREEN_H)
		_warn_p2.hide()
	else:
		_p2.panel.custom_minimum_size = Vector2(_PANEL_MIN_W, 0.0)
		_p2.panel.position = Vector2(_SCREEN_W * 0.5 + _MARGIN, _PANEL_Y)
		_warn_p1.size = Vector2(_SCREEN_W * 0.5, _SCREEN_H)
		_warn_p2.position = Vector2(_SCREEN_W * 0.5, 0.0)
		_warn_p2.size = Vector2(_SCREEN_W * 0.5, _SCREEN_H)


func _connect_signals() -> void:
	EventBus.health_changed.connect(_on_health_changed)
	EventBus.xp_updated.connect(_on_xp_updated)
	EventBus.entity_died.connect(_on_entity_died)
	EventBus.power_up_applied.connect(_on_power_up_applied)


func _on_health_changed(entity: LivingEntity, current: float, maximum: float) -> void:
	if entity == _player1:
		_update_health(_p1, current, maximum)
		_warn_tween_p1 = _get_active_tween(_warn_p1, _warn_tween_p1, current, maximum)
	elif is_instance_valid(_player2) and entity == _player2:
		_update_health(_p2, current, maximum)
		_warn_tween_p2 = _get_active_tween(_warn_p2, _warn_tween_p2, current, maximum)


func _on_xp_updated(entity: LivingEntity, current_xp: float, required_xp: float, level: int) -> void:
	if entity == _player1:
		if level > _prev_level_p1 and GameConfig.hud_show_xp_flash:
			_flash_xp_bar(_p1.xp_bar)
		_prev_level_p1 = level
		_update_xp(_p1, current_xp, required_xp, level)
	elif is_instance_valid(_player2) and entity == _player2:
		if level > _prev_level_p2 and GameConfig.hud_show_xp_flash:
			_flash_xp_bar(_p2.xp_bar)
		_prev_level_p2 = level
		_update_xp(_p2, current_xp, required_xp, level)


func _on_entity_died(entity: LivingEntity) -> void:
	if entity == _player1:
		_p1.panel.modulate.a = 0.4
		_stop_warning(_warn_p1, _warn_tween_p1)
		_warn_tween_p1 = null
		return
	if is_instance_valid(_player2) and entity == _player2:
		_p2.panel.modulate.a = 0.4
		_stop_warning(_warn_p2, _warn_tween_p2)
		_warn_tween_p2 = null
		return
	var killer := entity.last_attacker
	if not is_instance_valid(killer):
		return
	if killer == _player1:
		_kills1 += 1
		_p1.kill_count.text = str(_kills1)
	elif is_instance_valid(_player2) and killer == _player2:
		_kills2 += 1
		_p2.kill_count.text = str(_kills2)


func _on_power_up_applied(entity: LivingEntity, power_up: PowerUpData) -> void:
	var abbrev: String = _POWERUP_ABBREVS.get(power_up.stat_key, power_up.stat_key)
	if entity == _player1:
		_add_powerup_chip(_p1.powerup_row, abbrev, _COLOR_P1)
	elif is_instance_valid(_player2) and entity == _player2:
		_add_powerup_chip(_p2.powerup_row, abbrev, _COLOR_P2)


func _add_powerup_chip(row: HFlowContainer, text: String, color: Color) -> void:
	var chip := Label.new()
	chip.text = "[" + text + "]"
	chip.add_theme_font_size_override("font_size", 12)
	chip.modulate = color
	row.add_child(chip)


func _update_health(refs: _PanelRefs, current: float, maximum: float) -> void:
	if maximum > 0.0:
		refs.hp_bar.value = current / maximum
	refs.hp_text.text = str(int(current)) + " / " + str(int(maximum))


func _update_xp(refs: _PanelRefs, current_xp: float, required_xp: float, level: int) -> void:
	refs.lv_label.text = "LV " + str(level + 1)
	if required_xp > 0.0:
		refs.xp_bar.value = current_xp / required_xp


func _flash_xp_bar(bar: ProgressBar) -> void:
	var t := create_tween()
	t.tween_property(bar, "modulate", Color(1.8, 1.8, 0.3, 1.0), 0.15)
	t.tween_property(bar, "modulate", Color.WHITE, 0.25)


func _get_active_tween(rect: ColorRect, existing: Tween,
		current: float, maximum: float) -> Tween:
	if not GameConfig.hud_show_low_hp_warning:
		return existing
	var ratio := current / maximum if maximum > 0.0 else 1.0
	if ratio < 0.25:
		if existing and existing.is_running():
			return existing
		_stop_warning(rect, existing)
		rect.show()
		var t := create_tween().set_loops()
		t.tween_property(rect, "modulate:a", 0.20, 0.45)
		t.tween_property(rect, "modulate:a", 0.04, 0.45)
		return t
	else:
		_stop_warning(rect, existing)
		return null


func _stop_warning(rect: ColorRect, tween: Tween) -> void:
	if tween:
		tween.kill()
	rect.hide()


func _build_timer_label() -> void:
	var bar := Control.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.custom_minimum_size = Vector2(0, 36)
	add_child(bar)

	_timer_label = Label.new()
	_timer_label.text = "0:00"
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_timer_label.add_theme_font_size_override("font_size", 18)
	_timer_label.modulate = Color(0.85, 0.85, 0.9)
	bar.add_child(_timer_label)


func _build_warnings() -> void:
	_warn_p1 = ColorRect.new()
	_warn_p1.color = Color(1.0, 0.0, 0.0, 0.12)
	_warn_p1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_warn_p1.hide()
	add_child(_warn_p1)

	_warn_p2 = ColorRect.new()
	_warn_p2.color = Color(1.0, 0.0, 0.0, 0.12)
	_warn_p2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_warn_p2.hide()
	add_child(_warn_p2)


func _build_panel(accent: Color) -> _PanelRefs:
	var refs := _PanelRefs.new()

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = _COLOR_BG
	style.border_color = accent
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	panel.add_theme_stylebox_override("panel", style)
	refs.panel = panel

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	# Health row
	var health_row := HBoxContainer.new()
	health_row.add_theme_constant_override("separation", 8)
	vbox.add_child(health_row)
	refs.health_row = health_row

	var hp_lbl := Label.new()
	hp_lbl.text = "HP"
	hp_lbl.modulate = accent
	hp_lbl.add_theme_font_size_override("font_size", 13)
	hp_lbl.custom_minimum_size = Vector2(28, 0)
	health_row.add_child(hp_lbl)

	var hp_bar := ProgressBar.new()
	hp_bar.min_value = 0.0
	hp_bar.max_value = 1.0
	hp_bar.value = 1.0
	hp_bar.show_percentage = false
	hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_bar.custom_minimum_size = Vector2(140, 16)
	health_row.add_child(hp_bar)
	refs.hp_bar = hp_bar

	var hp_text := Label.new()
	hp_text.text = "100 / 100"
	hp_text.add_theme_font_size_override("font_size", 13)
	hp_text.custom_minimum_size = Vector2(75, 0)
	health_row.add_child(hp_text)
	refs.hp_text = hp_text

	# XP row
	var xp_row := HBoxContainer.new()
	xp_row.add_theme_constant_override("separation", 8)
	vbox.add_child(xp_row)
	refs.xp_row = xp_row

	var lv_lbl := Label.new()
	lv_lbl.text = "LV 1"
	lv_lbl.modulate = accent
	lv_lbl.add_theme_font_size_override("font_size", 13)
	lv_lbl.custom_minimum_size = Vector2(44, 0)
	xp_row.add_child(lv_lbl)
	refs.lv_label = lv_lbl

	var xp_bar := ProgressBar.new()
	xp_bar.min_value = 0.0
	xp_bar.max_value = 1.0
	xp_bar.value = 0.0
	xp_bar.show_percentage = false
	xp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	xp_bar.custom_minimum_size = Vector2(140, 16)
	xp_row.add_child(xp_bar)
	refs.xp_bar = xp_bar

	# Kill row
	var kill_row := HBoxContainer.new()
	kill_row.add_theme_constant_override("separation", 8)
	vbox.add_child(kill_row)
	refs.kill_row = kill_row

	var kill_lbl := Label.new()
	kill_lbl.text = "Kills:"
	kill_lbl.modulate = accent
	kill_lbl.add_theme_font_size_override("font_size", 13)
	kill_row.add_child(kill_lbl)

	var kill_count := Label.new()
	kill_count.text = "0"
	kill_count.add_theme_font_size_override("font_size", 13)
	kill_row.add_child(kill_count)
	refs.kill_count = kill_count

	# Power-up row
	var powerup_row := HFlowContainer.new()
	powerup_row.add_theme_constant_override("h_separation", 6)
	powerup_row.add_theme_constant_override("v_separation", 4)
	vbox.add_child(powerup_row)
	refs.powerup_row = powerup_row

	return refs
