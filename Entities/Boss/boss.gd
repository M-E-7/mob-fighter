extends LivingEntity
class_name Boss
## Boss entity — a large LivingEntity in the "enemy" and "boss" groups.
## The level_objective_component scales its HP and calls configure() to set name + palette.

@export_group("Boss Stats")
@export var boss_health: float = 500.0
@export var boss_health_max: float = 2000.0

var _display_name: String = "BOSS"


func _ready() -> void:
	add_to_group("enemy")
	add_to_group("boss")
	EventBus.entity_died.connect(_on_entity_died)
	EventBus.entity_damaged.connect(_on_entity_damaged)


func configure(p_display_name: String, color: Color) -> void:
	_display_name = p_display_name
	bullet_color = color
	var neon := get_node_or_null("NeonShaderComponent") as NeonShaderComponent
	if is_instance_valid(neon):
		neon.neon_color = color
		var visual := neon.get_visual()
		if visual and visual.material is ShaderMaterial:
			(visual.material as ShaderMaterial).set_shader_parameter("neon_color", color)
