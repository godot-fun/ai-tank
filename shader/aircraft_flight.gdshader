shader_type canvas_item;

uniform float phase_offset : hint_range(0.0, 6.283) = 0.0;
uniform float world_scale : hint_range(0.01, 4.0) = 1.0;
uniform float sway_strength : hint_range(0.0, 40.0) = 8.0;
uniform float sway_speed : hint_range(0.0, 12.0) = 3.2;
uniform float bob_strength : hint_range(0.0, 20.0) = 3.0;
uniform float tilt_strength : hint_range(0.0, 0.2) = 0.025;
uniform float engine_glow : hint_range(0.0, 2.0) = 1.2;

void vertex() {
	float local_scale = max(world_scale, 0.001);
	float t = TIME * sway_speed + phase_offset;

	float sway = sin(t) * (sway_strength / local_scale);
	float bob = cos(t * 1.35) * (bob_strength / local_scale);
	float vibration = sin(t * 9.0) * (0.8 / local_scale);
	float angle = sin(t * 1.1) * tilt_strength;
	float stretch = 1.0 + sin(t * 2.4) * 0.012;

	float c = cos(angle);
	float s = sin(angle);
	vec2 rotated = vec2(
		VERTEX.x * c - VERTEX.y * s,
		VERTEX.x * s + VERTEX.y * c
	);

	VERTEX = rotated * vec2(1.0, stretch);
	VERTEX.x += sway + vibration;
	VERTEX.y += bob;
}

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float cyan = smoothstep(0.05, 0.35, color.b - color.r)
		* smoothstep(0.2, 0.7, color.g)
		* color.a;
	float pulse = 0.55 + sin(TIME * 14.0 + phase_offset) * 0.45;

	color.rgb += cyan * vec3(0.15, 0.55, 1.0) * pulse * engine_glow;
	COLOR = color;
}
