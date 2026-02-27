extends Node
class_name NeonShaderComponent

const SHADER_PATH := "res://Components/Shaders/neon_shader.gdshader"

@export var entity: LivingEntity

@export_group("Neon")
@export var neon_color: Color = Color(1.0, 0.0, 0.2, 1.0)
@export_range(1.0, 5.0, 0.1) var glow_intensity: float = 2.5
@export_range(0.01, 0.3, 0.005) var outline_width: float = 0.06
@export_range(0.01, 0.5, 0.01) var glow_feather: float = 0.15

@export_group("Pulse")
@export_range(0.0, 10.0, 0.5) var pulse_speed: float = 2.0
@export_range(0.0, 1.0, 0.05) var pulse_amount: float = 0.4


func _ready() -> void:
	if not entity:
		return
	var visual := _find_visual()
	if not visual:
		push_warning("NeonShaderComponent: No visual node found on entity '%s'" % entity.name)
		return
	var material := ShaderMaterial.new()
	material.shader = load(SHADER_PATH)
	material.set_shader_parameter("neon_color", neon_color)
	material.set_shader_parameter("glow_intensity", glow_intensity)
	material.set_shader_parameter("outline_width", outline_width)
	material.set_shader_parameter("glow_feather", glow_feather)
	material.set_shader_parameter("pulse_speed", pulse_speed)
	material.set_shader_parameter("pulse_amount", pulse_amount)
	visual.material = material


# Looks for CircleDisplay first (MeshInstance2D), falls back to SpriteDisplay,
# then any Sprite2D or MeshInstance2D child.
func _find_visual() -> CanvasItem:
	var node: Node = entity.get_node_or_null("CircleDisplay")
	if node is CanvasItem:
		return node as CanvasItem
	node = entity.get_node_or_null("SpriteDisplay")
	if node is CanvasItem:
		return node as CanvasItem
	for child in entity.get_children():
		if child is MeshInstance2D or child is Sprite2D:
			return child as CanvasItem
	return null
