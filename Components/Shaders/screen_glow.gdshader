shader_type canvas_item;
render_mode blend_add, unshaded;

// Cheap LDR bloom: bright-pass the rendered frame and add back blurred copies
// sampled from a few mip levels (no HDR 2D / environment glow needed).
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float threshold : hint_range(0.0, 1.0) = 0.55;
uniform float strength : hint_range(0.0, 3.0) = 0.9;

vec3 bright(vec3 c) {
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	return c * (max(l - threshold, 0.0) / max(l, 0.0001));
}

void fragment() {
	// Lower mips are pre-blurred by the GPU, so a few LOD taps give a soft,
	// multi-scale halo for the cost of a handful of texture fetches.
	vec3 g = bright(textureLod(screen_tex, SCREEN_UV, 2.0).rgb) * 0.5;
	g += bright(textureLod(screen_tex, SCREEN_UV, 3.0).rgb) * 0.35;
	g += bright(textureLod(screen_tex, SCREEN_UV, 4.0).rgb) * 0.30;
	g += bright(textureLod(screen_tex, SCREEN_UV, 5.0).rgb) * 0.22;
	COLOR = vec4(g * strength, 1.0);
}
