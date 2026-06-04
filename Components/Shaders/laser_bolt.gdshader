shader_type canvas_item;
render_mode blend_add;

uniform vec4 beam_color : source_color = vec4(1.0, 0.15, 0.05, 1.0);
uniform float brightness : hint_range(0.0, 3.0) = 1.0;

void fragment() {
	float u = UV.x * 2.0 - 1.0;  // -1..+1 along beam (travel direction)
	float v = UV.y * 2.0 - 1.0;  // -1..+1 perpendicular

	// Taper both ends into rounded pill caps
	float length_fade = 1.0 - smoothstep(0.6, 1.0, abs(u));

	float r = abs(v);

	// Core: tight warm-white spine
	float glow_core = exp(-pow(r / 0.2, 2.0)) * length_fade;

	// Body: main red neon volume
	float body_r = max(0.001, 0.65 * length_fade);
	float glow_body = pow(max(0.0, 1.0 - r / body_r), 1.8) * length_fade;

	// Halo: wide soft fringe
	float glow_halo = pow(max(0.0, 1.0 - r), 4.0) * length_fade;

	// Keep channel values in reasonable range — additive blending handles brightness
	vec3 col_core = vec3(1.0, 0.7, 0.5);
	vec3 col_body = beam_color.rgb;
	vec3 col_halo = beam_color.rgb * 0.3;

	vec3 light = col_core * glow_core
	           + col_body * glow_body
	           + col_halo * glow_halo;

	COLOR = vec4(light * brightness, 1.0);
}
