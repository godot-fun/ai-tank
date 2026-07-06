shader_type canvas_item;

uniform float gloss_speed : hint_range(0.1, 3.0) = 1.0;
// Traveling specular band across plate surfaces.
uniform float streak_strength : hint_range(0.0, 0.5) = 0.22;
// Horizontal brushed-metal sheen scroll.
uniform float brush_strength : hint_range(0.0, 0.35) = 0.1;
// Sharp glints on rivets and beveled edges.
uniform float glint_strength : hint_range(0.0, 0.45) = 0.18;
uniform float rivet_pulse : hint_range(0.0, 0.18) = 0.045;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float t = TIME * gloss_speed;

	vec4 col = texture(TEXTURE, UV);
	float lum = dot(col.rgb, vec3(0.299, 0.587, 0.114));

	float metal_mask = smoothstep(0.18, 0.55, lum) * (1.0 - smoothstep(0.92, 1.0, lum));
	float highlight_mask = smoothstep(0.42, 0.78, lum);

	vec2 streak_dir = normalize(vec2(0.72, 0.35));
	float phase = dot(world_pos, streak_dir);

	// Two staggered gloss bands sliding diagonally across the wall.
	float band_a = fract(phase * 0.045 - t * 0.22);
	float streak_a = smoothstep(0.0, 0.06, band_a) * smoothstep(0.22, 0.06, band_a);

	float band_b = fract(phase * 0.045 - t * 0.22 + 0.52);
	float streak_b = smoothstep(0.0, 0.04, band_b) * smoothstep(0.14, 0.04, band_b);
	float streak = streak_a + streak_b * 0.55;

	// Brushed steel: scrolling horizontal sheen.
	float brush = sin(world_pos.y * 0.12 - t * 0.65 + phase * 0.3);
	brush = pow(max(0.0, brush), 2.4);

	// Micro-glints that twinkle across bright metal.
	float spark_a = sin(world_pos.x * 0.09 + world_pos.y * 0.07 + t * 1.2);
	float spark_b = sin(world_pos.x * 0.13 - world_pos.y * 0.1 + t * 0.95 + 1.7);
	float sparkle = max(0.0, spark_a * spark_b) * 2.4;

	float pulse = sin(t * 0.8 + phase * 0.5) * rivet_pulse;

	col.rgb += streak * streak_strength * metal_mask;
	col.rgb += brush * brush_strength * metal_mask;
	col.rgb += sparkle * glint_strength * highlight_mask;
	col.rgb += pulse * highlight_mask;

	// Cool specular kick on the moving gloss band.
	col.rgb += streak * vec3(0.07, 0.09, 0.13) * metal_mask;

	vec3 steel_tint = vec3(0.84, 0.91, 1.14);
	float tint_mix = clamp(streak * 0.38 + sparkle * 0.16 + brush * 0.12, 0.0, 0.48) * metal_mask;
	col.rgb = mix(col.rgb, col.rgb * steel_tint + vec3(0.04, 0.05, 0.08) * streak, tint_mix);

	COLOR = col;
}
