extends Node2D
class_name SpawnFXComponent

@export_group("References")
@export var entity: LivingEntity
@export var neon_component: NeonShaderComponent
@export var hit_flash_component: HitFlashComponent
@export var ring_mesh: MeshInstance2D

@export_group("Settings")
@export_range(0.1, 2.0, 0.05) var spawn_duration: float = 0.45
@export var invulnerable_while_spawning: bool = false

@export_range(1.0, 3.0, 0.1) var ring_overbright: float = 1.8


func _ready() -> void:
	# Deferred so NeonShaderComponent has created its material and found the visual.
	_begin_spawn.call_deferred()


func _begin_spawn() -> void:
	var visual: Node2D = null
	if neon_component:
		visual = neon_component.get_visual() as Node2D
	if not visual or not ring_mesh:
		return
	var base_scale := visual.scale
	visual.scale = base_scale * 0.05
	if hit_flash_component:
		hit_flash_component.scale_locked = true
	if invulnerable_while_spawning and entity and entity.hurtboxComponent:
		entity.hurtboxComponent.set_deferred("monitorable", false)

	var color := neon_component.neon_color
	var mat := ring_mesh.material as ShaderMaterial
	mat.set_shader_parameter("ring_color",
		Color(color.r * ring_overbright, color.g * ring_overbright, color.b * ring_overbright, 1.0))
	mat.set_shader_parameter("progress", 1.0)
	ring_mesh.visible = true

	# Ring runs in reverse (1 → 0): it implodes and flares as the body condenses.
	var tween := create_tween().set_parallel(true)
	tween.tween_property(visual, "scale", base_scale, spawn_duration) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(mat, "shader_parameter/progress", 0.0, spawn_duration)
	tween.tween_method(neon_component.set_flash, 1.0, 0.0, spawn_duration)
	tween.chain().tween_callback(_on_spawn_finished)


func _on_spawn_finished() -> void:
	ring_mesh.visible = false
	if hit_flash_component:
		hit_flash_component.scale_locked = false
	if invulnerable_while_spawning and entity and entity.hurtboxComponent:
		entity.hurtboxComponent.set_deferred("monitorable", true)
