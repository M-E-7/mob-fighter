shader_type canvas_item;
render_mode blend_add;

uniform vec4 beam_color : source_color = vec4(0.0, 0.625, 0.5, 1.0);
uniform float brightness : hint_range(0.0, 5.0) = 1.0;
uniform float time_offset = 0.0;
uniform float shimmer_strength : hint_range(0.0, 1.0) = 0.25;
uniform float shimmer_speed : hint_range(0.0, 30.0) = 8.0;

void fragment() {
	float v = 1.0 - UV.y;        // 0 = nozzle, 1 = tip
	float u = UV.x * 2.0 - 1.0; // -1 to +1 centered

	float t = time_offset * shimmer_speed;

	// Two-frequency undulation — primary wave + subtle harmonic for texture
	float shimmer = sin(t       + v * 9.0) * 0.65
	              + sin(t * 2.3 + v * 5.5) * 0.35;

	// Cone occupies central 65% of the quad; outer 27% is halo room
	float cone_hw = max(0.001, (1.0 - v) * 0.65 * (1.0 + shimmer * shimmer_strength));
	float halo_hw = max(0.001, (1.0 - v) * 0.92);

	// Slow lateral ion-stream drift
	float drift = sin(t * 0.6 + v * 5.0) * 0.06 * shimmer_strength * (1.0 - v);
	float dist   = abs(u + drift);

	// Core: gaussian hot-spot spine
	float r_core    = cone_hw * 0.22;
	float glow_core = exp(-pow(dist / max(r_core, 0.0001), 2.0));

	// Body: main neon plasma volume
	float norm_body = clamp(dist / cone_hw, 0.0, 1.0);
	float glow_body = pow(1.0 - norm_body, 1.8);

	// Halo: wide soft fringe — gives volumetric neon glow
	float norm_halo = clamp(dist / halo_hw, 0.0, 1.0);
	float glow_halo = pow(1.0 - norm_halo, 4.0);

	// Hot nozzle: core bleeds white-hot, cools to neon along the beam
	float heat    = pow(1.0 - v, 2.0);
	vec3 col_core = mix(beam_color.rgb * 1.5, vec3(2.5), heat * 0.85);
	vec3 col_body = beam_color.rgb * mix(1.0, 1.8, heat * 0.4);
	vec3 col_halo = beam_color.rgb * 0.5;

	// Core persists longest; halo fades fast toward tip
	float fade_core = pow(1.0 - v, 0.25);
	float fade_body = pow(1.0 - v, 0.55);
	float fade_halo = pow(1.0 - v, 2.0);

	// Subtle high-freq plasma instability flicker
	float flicker = 0.92 + 0.08 * sin(time_offset * 47.3) * sin(time_offset * 31.7 + 2.1);

	vec3 light = col_core * glow_core * fade_core * 2.0
	           + col_body * glow_body * fade_body * 0.9
	           + col_halo * glow_halo * fade_halo * 0.35;

	COLOR = vec4(light * brightness * flicker, 1.0);
}
