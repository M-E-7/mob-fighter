extends Node2D
class_name MuzzleFlashFX

@export_group("References")
@export var flash: GPUParticles2D
@export var sparks: GPUParticles2D

const _MAX_LIFETIME: float = 0.6


func play(color: Color, direction: Vector2) -> void:
	rotation = direction.angle()
	flash.modulate = _overbright(color, 2.0)
	sparks.modulate = _overbright(color, 1.4)
	flash.emitting = true
	sparks.emitting = true
	sparks.finished.connect(queue_free)
	get_tree().create_timer(_MAX_LIFETIME).timeout.connect(queue_free)


func _overbright(color: Color, factor: float) -> Color:
	return Color(color.r * factor, color.g * factor, color.b * factor, 1.0)
