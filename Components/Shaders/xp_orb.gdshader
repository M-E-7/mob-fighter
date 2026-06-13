shader_type canvas_item;
render_mode blend_add, unshaded;

global uniform float mus_bass;

uniform vec4 orb_color : source_color = vec4(1.0, 0.8, 0.15, 1.0);
uniform float brightness : hint_range(0.0, 3.0) = 1.0;
uniform float pulse_speed : hint_range(0.0, 10.0) = 3.0;
uniform float bass_glow : hint_range(0.0, 2.0) = 0.6;

void fragment() {
	vec2 p = UV - 0.5;
	float dist = length(p);
	float pulse = 1.0 + 0.12 * sin(TIME * pulse_speed);

	float core = exp(-dist * dist / 0.008);
	float body = exp(-dist * dist / 0.03);
	// Halo breathes with the bass via the music shader global.
	float halo = exp(-dist * dist / 0.09) * (0.35 + mus_bass * bass_glow);

	// Slowly rotating 4-point star sparkle.
	float ang = atan(p.y, p.x) + TIME * 0.8;
	float star = pow(abs(cos(ang * 2.0)), 8.0) * exp(-dist / 0.22) * 0.5;

	float energy = (core * 1.6 + body * 0.9 + halo + star) * pulse * brightness;
	COLOR = vec4(orb_color.rgb * energy, min(energy, 1.0) * orb_color.a);
}
