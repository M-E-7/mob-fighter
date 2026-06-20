extends CanvasLayer
class_name HUD

class _PanelRefs:
	var panel: PanelContainer
	var health_row: Control
	var hp_bar: ProgressBar
	var hp_text: Label
	var kill_row: Control
	var kill_count: Label
	var powerup_row: HFlowContainer

const _COLOR_P1 := Color(0.0, 1.0, 0.9)
const _COLOR_P2 := Color(1.0, 0.6, 0.0)
const _COLOR_BG := Color(0.05, 0.05, 0.08, 0.92)
const _COLOR_XP := Color(1.0, 0.85, 0.2)
const _LOW_HP_THRESHOLD := 0.25
const _SPIKE_DECAY := 0.45
const _THEME := preload("res://UI/Themes/neon_theme.tres")
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
var _bits_label: Label

var _warn_p1: ColorRect
var _warn_p2: ColorRect
var _low_hp_p1: float = 0.0
var _low_hp_p2: float = 0.0
var _hurt_spike_p1: float = 0.0
var _hurt_spike_p2: float = 0.0
var _vignette_time: float = 0.0


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_PAUSABLE

	_p1 = _build_panel(_COLOR_P1)
	add_child(_p1.panel)
	_p2 = _build_panel(_COLOR_P2)
	add_child(_p2.panel)

	_build_timer_label()
	_build_bits_label()
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
	_set_bits(RunState.currency)


func get_survival_time() -> float:
	return _survival_time


func get_kills(player: int) -> int:
	return _kills1 if player == 1 else _kills2


func _process(delta: float) -> void:
	_update_vignettes(delta)
	if not is_instance_valid(_player1):
		return
	_survival_time += delta
	var secs := int(_survival_time)
	_timer_label.text = "%d:%02d" % [secs / 60, secs % 60]


func _init_display(entity: LivingEntity, refs: _PanelRefs) -> void:
	if entity.healthComponent:
		_update_health(refs, entity.healthComponent.current_health, entity.healthComponent.max_health)


func _apply_settings() -> void:
	_p1.health_row.visible = GameConfig.hud_show_health
	_p2.health_row.visible = GameConfig.hud_show_health
	_bits_label.visible = GameConfig.hud_show_xp
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
	EventBus.currency_changed.connect(_on_currency_changed)
	EventBus.entity_died.connect(_on_entity_died)
	EventBus.entity_damaged.connect(_on_entity_damaged)
	EventBus.power_up_applied.connect(_on_power_up_applied)


func _on_health_changed(entity: LivingEntity, current: float, maximum: float) -> void:
	if entity == _player1:
		_update_health(_p1, current, maximum)
		_low_hp_p1 = _low_hp_severity(current, maximum)
	elif is_instance_valid(_player2) and entity == _player2:
		_update_health(_p2, current, maximum)
		_low_hp_p2 = _low_hp_severity(current, maximum)


func _on_entity_damaged(entity: LivingEntity, _amount: float) -> void:
	if not GameConfig.hud_show_low_hp_warning:
		return
	if entity == _player1:
		_hurt_spike_p1 = 1.0
	elif is_instance_valid(_player2) and entity == _player2:
		_hurt_spike_p2 = 1.0


func _on_currency_changed(total: int) -> void:
	_set_bits(total)


func _on_entity_died(entity: LivingEntity) -> void:
	if entity == _player1:
		_p1.panel.modulate.a = 0.4
		_low_hp_p1 = 0.0
		_hurt_spike_p1 = 0.0
		_warn_p1.hide()
		return
	if is_instance_valid(_player2) and entity == _player2:
		_p2.panel.modulate.a = 0.4
		_low_hp_p2 = 0.0
		_hurt_spike_p2 = 0.0
		_warn_p2.hide()
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


func _low_hp_severity(current: float, maximum: float) -> float:
	if not GameConfig.hud_show_low_hp_warning or maximum <= 0.0:
		return 0.0
	var ratio := current / maximum
	if ratio >= _LOW_HP_THRESHOLD:
		return 0.0
	return 1.0 - ratio / _LOW_HP_THRESHOLD


func _update_vignettes(delta: float) -> void:
	_vignette_time += delta
	_hurt_spike_p1 = maxf(0.0, _hurt_spike_p1 - delta / _SPIKE_DECAY)
	_hurt_spike_p2 = maxf(0.0, _hurt_spike_p2 - delta / _SPIKE_DECAY)
	var pulse := 0.7 + 0.3 * sin(_vignette_time * 5.0)
	_apply_vignette(_warn_p1, _low_hp_p1 * pulse + _hurt_spike_p1 * 0.8)
	_apply_vignette(_warn_p2, _low_hp_p2 * pulse + _hurt_spike_p2 * 0.8)


func _apply_vignette(rect: ColorRect, intensity: float) -> void:
	if intensity <= 0.001:
		rect.hide()
		return
	rect.show()
	(rect.material as ShaderMaterial).set_shader_parameter("intensity", intensity)


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


func _build_bits_label() -> void:
	var bar := Control.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_top = 38.0
	bar.offset_bottom = 38.0
	add_child(bar)

	_bits_label = Label.new()
	_bits_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bits_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bits_label.add_theme_font_size_override("font_size", 22)
	_bits_label.modulate = _COLOR_XP
	bar.add_child(_bits_label)
	_set_bits(RunState.currency)


func _set_bits(total: int) -> void:
	_bits_label.text = "%d %s" % [total, RunState.CURRENCY_NAME]


func _build_warnings() -> void:
	_warn_p1 = _build_vignette()
	_warn_p2 = _build_vignette()


func _build_vignette() -> ColorRect:
	var rect := ColorRect.new()
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://Components/Shaders/damage_vignette.gdshader")
	mat.set_shader_parameter("intensity", 0.0)
	rect.material = mat
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.hide()
	add_child(rect)
	return rect


func _build_panel(accent: Color) -> _PanelRefs:
	var refs := _PanelRefs.new()

	var panel := PanelContainer.new()
	panel.theme = _THEME
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
	hp_bar.add_theme_stylebox_override("fill", _accent_fill(accent))
	health_row.add_child(hp_bar)
	refs.hp_bar = hp_bar

	var hp_text := Label.new()
	hp_text.text = "100 / 100"
	hp_text.add_theme_font_size_override("font_size", 13)
	hp_text.custom_minimum_size = Vector2(75, 0)
	health_row.add_child(hp_text)
	refs.hp_text = hp_text

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


func _accent_fill(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(3)
	return sb
