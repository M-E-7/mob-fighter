shader_type canvas_item;
render_mode unshaded;

uniform vec4 neon_color : source_color = vec4(1.0, 0.0, 0.2, 1.0);
// Width of the hard neon rim (in UV space, 0–1)
uniform float outline_width : hint_range(0.01, 0.3, 0.005) = 0.06;
// How wide the soft glow bleeds from the rim
uniform float glow_feather : hint_range(0.01, 0.5, 0.01) = 0.15;
uniform float glow_intensity : hint_range(1.0, 5.0, 0.1) = 2.5;
uniform float pulse_speed : hint_range(0.0, 10.0, 0.5) = 2.0;
uniform float pulse_amount : hint_range(0.0, 1.0, 0.05) = 0.4;

void fragment() {
	// Remap UV to [-0.5, 0.5] so the center is at 0,0
	vec2 uv = UV - vec2(0.5);
	float dist = length(uv);
	float radius = 0.45;

	float pulse = 1.0 + sin(TIME * pulse_speed) * pulse_amount;

	// Absolute distance from the circle rim (0 = exactly on rim)
	float sdf = abs(dist - radius);

	// Hard neon outline using smoothstep for anti-aliasing
	float outline = 1.0 - smoothstep(0.0, outline_width, sdf);

	// Soft exponential glow bleeding from the rim in both directions
	float glow = exp(-sdf / glow_feather);

	// Clip everything outside the quad boundary
	float mask = step(dist, 0.5);

	float alpha = clamp(outline + glow * 0.6, 0.0, 1.0) * mask;
	vec3 color = neon_color.rgb * glow_intensity * pulse * clamp(outline + glow, 0.0, 1.0);

	COLOR = vec4(color, alpha);
}
