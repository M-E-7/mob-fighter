shader_type canvas_item;
render_mode unshaded;

global uniform float mus_bass;
global uniform float mus_mid;
global uniform float mus_treble;
global uniform float mus_beat;

// Camera state pushed each frame by LevelVisualsController.
uniform vec2 cam_pos = vec2(0.0);
uniform float cam_rot = 0.0;
uniform float cam_zoom = 1.0;

uniform vec4 base_color : source_color = vec4(0.015, 0.015, 0.035, 1.0);
uniform vec4 bass_color : source_color = vec4(0.06, 0.02, 0.10, 1.0);
uniform vec4 nebula_color_a : source_color = vec4(0.45, 0.05, 0.55, 1.0);
uniform vec4 nebula_color_b : source_color = vec4(0.0, 0.45, 0.55, 1.0);
uniform vec4 grid_color : source_color = vec4(0.0, 0.55, 0.65, 1.0);
uniform float grid_size = 256.0;
uniform float grid_intensity : hint_range(0.0, 1.0) = 0.22;
uniform float star_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float nebula_strength : hint_range(0.0, 1.0) = 0.45;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float star_layer(vec2 world, float cell, float density, float t) {
	vec2 g = world / cell;
	vec2 id = floor(g);
	float rnd = hash21(id);
	if (rnd > density) {
		return 0.0;
	}
	vec2 star_pos = vec2(hash21(id + 7.31), hash21(id + 3.77));
	float d = length(fract(g) - star_pos);
	float twinkle = 0.6 + 0.4 * sin(t * (2.0 + rnd * 6.0) + rnd * 31.4);
	return exp(-d * d * 220.0) * twinkle;
}

float grid_line(vec2 world, float size, float width) {
	vec2 g = (0.5 - abs(fract(world / size) - 0.5)) * size;
	return 1.0 - smoothstep(0.0, width, min(g.x, g.y));
}

void fragment() {
	// Reconstruct the world position under this pixel so every layer is
	// rigid with the gameplay plane (correct under the rotating camera).
	vec2 screen_px = (SCREEN_UV - 0.5) / SCREEN_PIXEL_SIZE;
	float cr = cos(cam_rot);
	float sr = sin(cam_rot);
	vec2 rotated = vec2(screen_px.x * cr - screen_px.y * sr, screen_px.x * sr + screen_px.y * cr);
	vec2 world = cam_pos + rotated / cam_zoom;

	// Deep-space wash that leans purple with the bass and kicks on beats.
	vec3 col = mix(base_color.rgb, bass_color.rgb, mus_bass);
	col += vec3(0.04, 0.02, 0.06) * mus_beat;

	// Drifting two-octave nebula, parallax factor ~0.25.
	vec2 np = world * 0.25 * 0.0035 + vec2(TIME * 0.010, -TIME * 0.007);
	float n = vnoise(np) * 0.65 + vnoise(np * 2.3 + 13.7) * 0.35;
	n = smoothstep(0.45, 0.85, n);
	vec3 nebula = mix(nebula_color_a.rgb, nebula_color_b.rgb,
		vnoise(world * 0.0007 + TIME * 0.005));
	col += nebula * n * nebula_strength * (0.25 + 0.5 * mus_bass);

	// Three star layers, far to near; the near layer is overbright so it blooms.
	float tw = 0.7 + mus_treble * 0.8;
	col += vec3(0.80, 0.90, 1.0) * star_layer(world * 0.15, 90.0, 0.50, TIME) * 0.4 * star_intensity * tw;
	col += vec3(0.85, 0.95, 1.0) * star_layer(world * 0.35 + 500.0, 110.0, 0.45, TIME * 1.3) * 0.8 * star_intensity * tw;
	col += vec3(1.0) * star_layer(world * 0.6 + 1234.0, 140.0, 0.40, TIME * 1.7) * 1.6 * star_intensity * tw;

	// World-locked neon grid on the gameplay plane; beats light it up.
	float minor = grid_line(world, grid_size, 1.6);
	float major = grid_line(world, grid_size * 4.0, 2.4);
	col += grid_color.rgb * (minor * 0.35 + major * 0.8) * grid_intensity * (1.0 + mus_beat * 1.6);

	// Soft corner falloff for depth.
	col *= 1.0 - 0.25 * smoothstep(0.4, 0.75, length(SCREEN_UV - 0.5));

	COLOR = vec4(col, 1.0);
}
