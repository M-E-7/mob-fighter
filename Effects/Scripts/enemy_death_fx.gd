extends Node2D
class_name EnemyDeathFX

@export_group("References")
@export var ring_mesh: MeshInstance2D
@export var burst: GPUParticles2D
@export var embers: GPUParticles2D

@export_group("Settings")
@export_range(0.1, 2.0, 0.05) var ring_duration: float = 0.45
@export_range(1.0, 3.0, 0.1) var color_overbright: float = 1.8

const _MAX_LIFETIME: float = 2.5


func play(color: Color) -> void:
	var mat := ring_mesh.material as ShaderMaterial
	mat.set_shader_parameter("ring_color", _overbright(color, color_overbright))
	mat.set_shader_parameter("progress", 0.0)
	var tween := create_tween()
	tween.tween_property(mat, "shader_parameter/progress", 1.0, ring_duration)
	burst.modulate = _overbright(color, 1.4)
	embers.modulate = color
	burst.emitting = true
	embers.emitting = true
	embers.finished.connect(queue_free)
	# Fallback in case the particle signal never fires (e.g. node hidden).
	get_tree().create_timer(_MAX_LIFETIME).timeout.connect(queue_free)


func _overbright(color: Color, factor: float) -> Color:
	return Color(color.r * factor, color.g * factor, color.b * factor, 1.0)
