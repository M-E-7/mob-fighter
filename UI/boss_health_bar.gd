extends Control
class_name BossHealthBar
## Top-center boss HP bar shown during boss encounters.
## Plays a name-card banner on boss_spawned, updates the bar on health_changed,
## and shows a brief "SYSTEM PURGED" flash on entity_died.

const _BAR_WIDTH := 520.0
const _BANNER_DURATION := 2.5

var _boss: LivingEntity

var _bar_container: Control
var _name_label: Label
var _hp_bar: ProgressBar
var _purged_label: Label
var _banner: Control
var _banner_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_PAUSABLE
	hide()
	_build_hp_bar()
	_build_banner()
	EventBus.boss_spawned.connect(_on_boss_spawned)
	EventBus.health_changed.connect(_on_health_changed)
	EventBus.entity_died.connect(_on_entity_died)


func _on_boss_spawned(boss: LivingEntity, display_name: String, max_health: float) -> void:
	if not GameConfig.hud_show_boss_bar:
		return
	_boss = boss
	_name_label.text = display_name
	_banner_label.text = "  !! " + display_name + " !!"
	_hp_bar.max_value = max_health
	_hp_bar.value = max_health
	_purged_label.visible = false
	show()
	_play_intro()


func _on_health_changed(entity: LivingEntity, current: float, _max: float) -> void:
	if not is_instance_valid(_boss) or entity != _boss:
		return
	_hp_bar.value = current


func _on_entity_died(entity: LivingEntity) -> void:
	if not is_instance_valid(_boss) or entity != _boss:
		return
	_purged_label.visible = true
	_purged_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(1.0)
	tween.tween_property(_purged_label, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.7)
	tween.tween_callback(hide)
	tween.tween_callback(func() -> void: modulate.a = 1.0)


func _play_intro() -> void:
	_bar_container.modulate.a = 0.0
	_banner.modulate.a = 1.0
	_banner.show()
	var tween := create_tween()
	tween.tween_property(_bar_container, "modulate:a", 1.0, 0.4)
	tween.tween_interval(_BANNER_DURATION - 0.4)
	tween.tween_property(_banner, "modulate:a", 0.0, 0.5)
	tween.tween_callback(_banner.hide)


func _build_hp_bar() -> void:
	_bar_container = Control.new()
	_bar_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_bar_container.custom_minimum_size = Vector2(0, 58)
	_bar_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bar_container)

	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_name_label.offset_top = 4.0
	_name_label.offset_bottom = 28.0
	_name_label.add_theme_font_size_override("font_size", 17)
	_name_label.modulate = Color(1.0, 0.3, 0.3, 1.0)
	_bar_container.add_child(_name_label)

	_hp_bar = ProgressBar.new()
	_hp_bar.min_value = 0.0
	_hp_bar.max_value = 1.0
	_hp_bar.value = 1.0
	_hp_bar.show_percentage = false
	_hp_bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_hp_bar.offset_left = -_BAR_WIDTH * 0.5
	_hp_bar.offset_right = _BAR_WIDTH * 0.5
	_hp_bar.offset_top = 30.0
	_hp_bar.offset_bottom = 52.0
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.9, 0.08, 0.08, 1.0)
	fill.set_corner_radius_all(3)
	_hp_bar.add_theme_stylebox_override("fill", fill)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.07, 0.03, 0.03, 0.92)
	bg.border_color = Color(0.45, 0.07, 0.07, 1.0)
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(3)
	_hp_bar.add_theme_stylebox_override("background", bg)
	_bar_container.add_child(_hp_bar)

	_purged_label = Label.new()
	_purged_label.text = "SYSTEM PURGED"
	_purged_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_purged_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_purged_label.offset_left = -300.0
	_purged_label.offset_right = 300.0
	_purged_label.offset_top = 30.0
	_purged_label.offset_bottom = 52.0
	_purged_label.add_theme_font_size_override("font_size", 19)
	_purged_label.modulate = Color(0.4, 1.0, 0.5, 0.0)
	_purged_label.visible = false
	_bar_container.add_child(_purged_label)


func _build_banner() -> void:
	_banner = Control.new()
	_banner.set_anchors_preset(Control.PRESET_CENTER)
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_banner)

	_banner_label = Label.new()
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner_label.set_anchors_preset(Control.PRESET_CENTER)
	_banner_label.offset_left = -600.0
	_banner_label.offset_right = 600.0
	_banner_label.offset_top = -50.0
	_banner_label.offset_bottom = 50.0
	_banner_label.add_theme_font_size_override("font_size", 38)
	_banner_label.modulate = Color(1.0, 0.2, 0.2, 1.0)
	_banner.add_child(_banner_label)
	_banner.hide()
