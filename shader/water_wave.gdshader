shader_type canvas_item;

// World-space wave frequency (per pixel).
uniform float wave_frequency : hint_range(0.01, 0.3) = 0.06;
// UV offset amplitude; keep small to avoid visible seams at tile edges.
uniform float wave_strength : hint_range(0.0, 0.08) = 0.022;
uniform float wave_speed : hint_range(0.1, 5.0) = 1.4;
// Second layer adds depth without heavy distortion.
uniform float detail_strength : hint_range(0.0, 0.05) = 0.01;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float t = TIME * wave_speed;

	vec2 uv = UV;
	uv.x += sin(world_pos.y * wave_frequency + t) * wave_strength;
	uv.y += cos(world_pos.x * wave_frequency * 0.92 + t * 1.08) * wave_strength;

	uv.x += sin(world_pos.x * wave_frequency * 1.7 + t * 1.35) * detail_strength;
	uv.y += cos(world_pos.y * wave_frequency * 1.5 - t * 0.85) * detail_strength;

	COLOR = texture(TEXTURE, uv);
}
