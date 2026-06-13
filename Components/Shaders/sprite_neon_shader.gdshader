shader_type canvas_item;
render_mode unshaded;

uniform vec4 neon_color : source_color = vec4(1.0, 0.0, 0.2, 1.0);
uniform float glow_intensity : hint_range(1.0, 5.0, 0.1) = 2.5;
uniform float glow_feather : hint_range(0.01, 0.5, 0.01) = 0.15;
uniform float pulse_speed : hint_range(0.0, 10.0, 0.5) = 2.0;
uniform float pulse_amount : hint_range(0.0, 1.0, 0.05) = 0.4;
uniform float flash_amount : hint_range(0.0, 1.0, 0.01) = 0.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float pulse = 1.0 + sin(TIME * pulse_speed) * pulse_amount;
	// Pixel brightness drives the neon-trim mask (0 = dark hull, 1 = white trim)
	float luma = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	vec3 tinted = mix(tex.rgb, neon_color.rgb * glow_intensity * pulse, luma);
	tinted = mix(tinted, vec3(2.8), flash_amount * 0.85);
	COLOR = vec4(tinted, tex.a);
}
