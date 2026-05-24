extends Node2D
class_name FloatingTextManager

const _FloatingText := preload("res://UI/floating_text.gd")

const _COLOR_DAMAGE := Color(1.0, 0.9, 0.1)
const _COLOR_XP := Color(0.2, 1.0, 0.9)


func _ready() -> void:
	EventBus.entity_damaged.connect(_on_entity_damaged)
	EventBus.xp_orb_collected.connect(_on_xp_orb_collected)


func _on_entity_damaged(entity: LivingEntity, amount: float) -> void:
	if not GameConfig.hud_show_damage_numbers:
		return
	_spawn(entity.global_position, "-" + str(int(amount)), _COLOR_DAMAGE, 17)


func _on_xp_orb_collected(world_position: Vector2, amount: float) -> void:
	if not GameConfig.hud_show_xp_pickup_text:
		return
	_spawn(world_position, "+" + str(int(amount)) + " XP", _COLOR_XP, 14)


func _spawn(world_pos: Vector2, text: String, color: Color, font_size: int) -> void:
	var ft := _FloatingText.new()
	add_child(ft)
	ft.global_position = world_pos
	ft.setup(text, color, font_size)
