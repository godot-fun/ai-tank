shader_type canvas_item;

uniform float shield_active : hint_range(0.0, 1.0) = 1.0;
uniform float ring_speed : hint_range(0.1, 2.0) = 0.42;
uniform float ring_strength : hint_range(0.0, 0.5) = 0.2;
// UV radius band: 0 = center, 1 = edge midpoints (use UV, not VERTEX).
uniform float ring_inner : hint_range(0.0, 1.0) = 0.1;
uniform float ring_outer : hint_range(0.0, 1.5) = 0.95;

varying vec2 v_world;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float active = step(0.05, col.a) * step(0.001, shield_active);

	vec2 centered = UV - vec2(0.5);
	float dist = length(centered) * 2.0;

	float area_mask = smoothstep(ring_inner, ring_inner + 0.12, dist);
	area_mask *= 1.0 - smoothstep(ring_outer - 0.1, ring_outer, dist);

	float phase = dist * 5.5 - TIME * ring_speed;
	float wave = fract(phase);

	// Bright leading edge + soft trail (wider band for readability).
	float ring_a = pow(max(0.0, 1.0 - wave * 2.6), 1.6);
	float ring_b = pow(max(0.0, 1.0 - fract(phase + 0.55) * 2.6), 1.6);
	float ripple = (ring_a + ring_b * 0.65) * area_mask * active;

	float tint_mix = sin(TIME * 0.55 + dot(v_world, vec2(0.01, 0.008))) * 0.5 + 0.5;
	vec3 ripple_color = mix(vec3(0.35, 0.88, 1.25), vec3(1.25, 0.95, 0.4), tint_mix);

	col.rgb += ripple * ring_strength * ripple_color;
	col.rgb = mix(col.rgb, col.rgb + vec3(0.12, 0.2, 0.26), ripple * 0.65);

	COLOR = col;
}
