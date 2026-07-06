shader_type canvas_item;

uniform float wind_speed : hint_range(0.2, 3.0) = 0.85;
uniform float gust_speed : hint_range(0.05, 1.0) = 0.22;
// Tip horizontal bend in local pixels.
uniform float bend_strength : hint_range(0.0, 24.0) = 9.0;
// Tip flutter on top of main sway.
uniform float flutter_amount : hint_range(0.0, 1.0) = 0.28;
uniform float rotation_amount : hint_range(0.0, 0.12) = 0.038;

varying float v_tip;

void vertex() {
	float height = 1.0 / TEXTURE_PIXEL_SIZE.y;
	float half_height = height * 0.5;
	float height_norm = 1.0 - clamp((VERTEX.y + half_height) / height, 0.0, 1.0);
	// Stiff at roots, flexible at tips.
	float bend = height_norm * height_norm * (3.0 - 2.0 * height_norm);
	v_tip = height_norm;

	vec2 tile_world = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xy;
	float phase = dot(tile_world, vec2(0.031, 0.023));
	float t = TIME * wind_speed;

	// Slow gusts: breeze builds up, eases off.
	float gust = 0.45 + 0.55 * sin(TIME * gust_speed + phase * 0.35);
	gust = mix(gust, gust * gust, 0.55);

	float main_sway = sin(t * 0.95 + phase);
	float cross_sway = sin(t * 1.35 + phase * 1.15) * 0.22;
	float flutter = sin(t * 2.75 + phase * 1.6) * flutter_amount;
	float wind = (main_sway + cross_sway + flutter) * gust;

	vec2 pivot = vec2(0.0, half_height);
	vec2 rel = VERTEX - pivot;

	float angle = wind * rotation_amount * bend;
	float c = cos(angle);
	float s = sin(angle);
	vec2 rotated = vec2(rel.x * c - rel.y * s, rel.x * s + rel.y * c);

	float shear = wind * bend_strength * bend;
	VERTEX = rotated + pivot + vec2(shear, 0.0);
}

void fragment() {
	vec2 uv = UV;
	float tip = v_tip * v_tip;
	float t = TIME * wind_speed;
	uv.x += sin(t * 2.4 + UV.y * 14.0 + UV.x * 6.0) * 0.006 * tip;
	COLOR = texture(TEXTURE, uv);
}
