shader_type canvas_item;

uniform float breath_speed : hint_range(0.1, 3.0) = 0.55;
// Brick-face brightness pulse; keep readable at 60px tile size.
uniform float breath_strength : hint_range(0.0, 0.2) = 0.06;
uniform float mortar_depth : hint_range(0.0, 0.2) = 0.05;
// Mortar lines also breathe (darken / lighten with sin).
uniform float mortar_pulse : hint_range(0.0, 0.15) = 0.045;
uniform float warm_tint : hint_range(0.0, 0.35) = 0.18;
uniform float glint_speed : hint_range(0.1, 3.0) = 0.7;
uniform float glint_strength : hint_range(0.0, 0.4) = 0.11;
uniform float rivet_pulse : hint_range(0.0, 0.2) = 0.038;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float breath_t = TIME * breath_speed;
	float glint_t = TIME * glint_speed;
	float phase = dot(world_pos, vec2(0.018, 0.014));

	vec4 col = texture(TEXTURE, UV);
	float lum = dot(col.rgb, vec3(0.299, 0.587, 0.114));

	// Dark pixels = mortar / frame gaps; everything else = brick (multi-color safe).
	float mortar_mask = 1.0 - smoothstep(0.08, 0.24, lum);
	float brick_mask = 1.0 - mortar_mask;
	// Bevel tips and rivet highlights.
	float highlight_mask = smoothstep(0.38, 0.72, lum);

	float wave = sin(breath_t * 0.65 + phase);
	float breath = wave * breath_strength;

	col.rgb += breath * brick_mask;
	col.rgb -= mortar_depth * mortar_mask;
	col.rgb += wave * mortar_pulse * mortar_mask;

	float tint_mix = warm_tint * (0.55 + 0.45 * wave) * brick_mask;
	col.rgb = mix(col.rgb, col.rgb * vec3(0.88, 0.28, 0.22), tint_mix);

	float spark_a = sin(world_pos.x * 0.09 + world_pos.y * 0.07 + glint_t * 1.1);
	float spark_b = sin(world_pos.x * 0.13 - world_pos.y * 0.1 + glint_t * 0.85 + 1.7);
	float glint = max(0.0, spark_a * spark_b) * 2.4;

	float pulse = sin(glint_t * 0.8 + phase * 0.5) * rivet_pulse;

	col.rgb += glint * glint_strength * highlight_mask;
	col.rgb += glint * glint_strength * 0.35 * brick_mask;
	col.rgb += pulse * highlight_mask;
	col.rgb += glint * vec3(0.16, 0.03, 0.02) * highlight_mask * 0.06;

	COLOR = col;
}
