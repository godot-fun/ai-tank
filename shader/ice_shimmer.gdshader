shader_type canvas_item;

uniform float shimmer_speed : hint_range(0.1, 2.0) = 0.5;
uniform float shimmer_strength : hint_range(0.0, 0.35) = 0.1;
uniform float frost_pulse : hint_range(0.0, 0.12) = 0.035;
// Subtle frozen-surface refraction; much weaker than water.
uniform float refract_strength : hint_range(0.0, 0.025) = 0.005;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float t = TIME * shimmer_speed;

	vec2 uv = UV;
	uv.x += sin(world_pos.y * 0.048 + t * 0.55) * refract_strength;
	uv.y += cos(world_pos.x * 0.044 + t * 0.48) * refract_strength;

	vec4 col = texture(TEXTURE, uv);
	float lum = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	float highlight_mask = smoothstep(0.5, 0.82, lum);

	float shimmer_a = sin(world_pos.x * 0.07 + world_pos.y * 0.055 + t);
	float shimmer_b = sin(world_pos.x * 0.095 - world_pos.y * 0.08 + t * 0.82 + 1.4);
	float glint = max(0.0, shimmer_a * shimmer_b) * 2.2;

	float pulse = sin(t * 0.65 + dot(world_pos, vec2(0.018, 0.014))) * frost_pulse;

	col.rgb += glint * shimmer_strength * highlight_mask;
	col.rgb += pulse * highlight_mask;
	col.rgb = mix(col.rgb, col.rgb * vec3(0.94, 1.03, 1.1), glint * 0.12 * highlight_mask);

	COLOR = col;
}
