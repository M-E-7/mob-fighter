extends Node2D
class_name FloatingText

var _text: String = ""
var _color: Color = Color.WHITE
var _font_size: int = 16
var _alpha: float = 1.0


func setup(text: String, color: Color, font_size: int = 16) -> void:
	_text = text
	_color = color
	_font_size = font_size
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 44.0, 0.85)
	tween.tween_property(self, "_alpha", 0.0, 0.85)
	tween.chain().tween_callback(queue_free)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var pos := Vector2(-_font_size, 0)
	var outline := Color(0.0, 0.0, 0.05, _alpha * 0.85)
	draw_string_outline(font, pos, _text,
			HORIZONTAL_ALIGNMENT_CENTER, -1, _font_size, 4, outline)
	# Overbright fill blooms in the HDR world canvas.
	var bright := Color(_color.r * 1.6, _color.g * 1.6, _color.b * 1.6, _alpha)
	draw_string(font, pos, _text,
			HORIZONTAL_ALIGNMENT_CENTER, -1, _font_size, bright)
