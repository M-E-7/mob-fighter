shader_type canvas_item;
render_mode blend_add, unshaded;

uniform vec4 ring_color : source_color = vec4(0.0, 1.0, 0.9, 1.0);
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float brightness : hint_range(0.0, 4.0) = 1.6;

void fragment() {
	vec2 p = UV - 0.5;
	float dist = length(p);
	float radius = progress * 0.46;
	// Ring sharpens as it expands so the leading edge stays crisp.
	float width = mix(0.06, 0.015, progress);
	float ring = exp(-pow((dist - radius) / width, 2.0));
	float fade = 1.0 - progress;
	// Center flash dies early so the expanding ring reads as the main event.
	float flash = exp(-dist * dist / 0.015) * max(0.0, 1.0 - progress * 4.0);
	float energy = ring * fade + flash;
	COLOR = vec4(ring_color.rgb * energy * brightness, energy * ring_color.a);
}
