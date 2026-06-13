shader_type canvas_item;
render_mode unshaded;

global uniform float mus_bass;

uniform vec4 panel_color : source_color = vec4(0.05, 0.06, 0.10, 1.0);
uniform vec4 line_color : source_color = vec4(0.0, 0.45, 0.55, 1.0);
uniform float scanline_spacing = 26.0;
uniform float scanline_speed = 18.0;
uniform float scanline_intensity : hint_range(0.0, 0.5) = 0.10;
uniform float bass_shimmer : hint_range(0.0, 2.0) = 0.5;

varying vec2 world_pos;

void vertex() {
	// _draw() rects carry no usable UVs — world coordinates are the only stable basis.
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec3 col = panel_color.rgb;

	// Diagonal scanlines drifting slowly across the panels.
	float diag = (world_pos.x + world_pos.y - TIME * scanline_speed) / scanline_spacing;
	float lines = smoothstep(0.85, 1.0, sin(diag) * 0.5 + 0.5);
	col += line_color.rgb * lines * scanline_intensity * (1.0 + mus_bass * bass_shimmer);

	// Faint per-tile value variation so large merged slabs don't read flat.
	vec2 tile = floor(world_pos / 64.0);
	float v = fract(sin(dot(tile, vec2(12.9898, 78.233))) * 43758.5453);
	col *= 0.92 + v * 0.16;

	COLOR = vec4(col, 1.0);
}
