extends Node2D
class_name BulletImpactFX

@export_group("References")
@export var sparks: GPUParticles2D
@export var flash: GPUParticles2D

const _MAX_LIFETIME: float = 1.0


func play(color: Color, direction: Vector2) -> void:
	# Emission direction follows node rotation (particles spawn in world space).
	rotation = direction.angle()
	sparks.modulate = _overbright(color, 1.4)
	flash.modulate = _overbright(color, 1.8)
	sparks.emitting = true
	flash.emitting = true
	sparks.finished.connect(queue_free)
	get_tree().create_timer(_MAX_LIFETIME).timeout.connect(queue_free)


func _overbright(color: Color, factor: float) -> Color:
	return Color(color.r * factor, color.g * factor, color.b * factor, 1.0)
