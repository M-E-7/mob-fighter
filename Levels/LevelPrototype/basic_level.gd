extends Node2D

@onready var _proc_gen: ProcGenLevelComponent = $ProcGenLevelComponent
@onready var _player: Node2D = $Player


func _ready() -> void:
	_proc_gen.level_generated.connect(_on_level_generated)


func _on_level_generated(spawn_pos: Vector2) -> void:
	_player.global_position = spawn_pos
