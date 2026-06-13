extends Node
class_name HitFlashComponent

@export_group("References")
@export var entity: LivingEntity
@export var neon_component: NeonShaderComponent

@export_group("Settings")
@export_range(0.02, 0.5, 0.01) var flash_decay: float = 0.12
@export_range(0.0, 1.0, 0.05) var flash_strength: float = 1.0
@export_range(1.0, 2.0, 0.01) var punch_scale: float = 1.18
@export_range(0.05, 0.5, 0.01) var punch_decay: float = 0.14

# SpawnFXComponent sets this while it owns the visual's scale.
var scale_locked: bool = false

var _flash: float = 0.0
var _punch: float = 0.0
var _base_scale: Vector2 = Vector2.ONE
var _base_scale_cached: bool = false


func _ready() -> void:
	EventBus.entity_damaged.connect(_on_entity_damaged)


func _process(delta: float) -> void:
	if _flash <= 0.0 and _punch <= 0.0:
		return
	_flash = maxf(0.0, _flash - delta / flash_decay)
	_punch = maxf(0.0, _punch - delta / punch_decay)
	if neon_component:
		neon_component.set_flash(_flash * flash_strength)
	_apply_punch()


func _on_entity_damaged(damaged: LivingEntity, _amount: float) -> void:
	if damaged != entity:
		return
	_flash = 1.0
	_punch = 1.0
	# While spawn FX owns the scale, the visual's scale is mid-tween — don't cache it.
	if not _base_scale_cached and neon_component and not scale_locked:
		var visual := neon_component.get_visual() as Node2D
		if visual:
			_base_scale = visual.scale
			_base_scale_cached = true


func _apply_punch() -> void:
	if scale_locked or not neon_component or not _base_scale_cached:
		return
	var visual := neon_component.get_visual() as Node2D
	if visual:
		visual.scale = _base_scale * (1.0 + (punch_scale - 1.0) * _punch)
