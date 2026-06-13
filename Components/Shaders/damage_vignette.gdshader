shader_type canvas_item;
render_mode unshaded;

uniform vec4 vignette_color : source_color = vec4(1.0, 0.04, 0.1, 1.0);
uniform float intensity : hint_range(0.0, 1.5) = 0.0;

void fragment() {
	vec2 c = UV - 0.5;
	float edge = smoothstep(0.2, 0.72, length(c));
	COLOR = vec4(vignette_color.rgb, edge * intensity * vignette_color.a);
}
