shader_type canvas_item;

uniform float flash_speed : hint_range(0.5, 10.0) = 2.4;
uniform float flash_min : hint_range(0.0, 1.0) = 0.55;
uniform float flash_max : hint_range(0.0, 2.0) = 1.15;
uniform float breathe_speed : hint_range(0.2, 4.0) = 1.8;
uniform float breathe_strength : hint_range(0.0, 0.12) = 0.035;
uniform float bob_speed : hint_range(0.2, 4.0) = 1.5;
uniform float bob_pixels : hint_range(0.0, 8.0) = 2.0;
uniform float border_pixels : hint_range(1.0, 128.0) = 10.0;
uniform vec4 border_color : source_color = vec4(1.0, 1.0, 1.0, 0.25);

varying vec2 v_static_pos;
varying vec2 v_quad_pos;
varying float v_phase;

void vertex() {
	v_phase = dot((MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xy, vec2(0.017, 0.023));
	v_static_pos = VERTEX;

	vec2 dir = sign(VERTEX);
	VERTEX += dir * border_pixels;
	v_quad_pos = VERTEX;
}

void fragment() {
	vec2 tex_half = 0.5 / TEXTURE_PIXEL_SIZE;
	vec2 tex_size = 1.0 / TEXTURE_PIXEL_SIZE;
	bool outside = abs(v_quad_pos.x) > tex_half.x || abs(v_quad_pos.y) > tex_half.y;

	float breathe = 1.0 + sin(TIME * breathe_speed + v_phase) * breathe_strength;
	vec2 bob = vec2(
		cos(TIME * bob_speed + v_phase * 1.15) * bob_pixels * 0.35,
		sin(TIME * bob_speed * 0.82 + v_phase) * bob_pixels
	);

	float wave_a = sin(TIME * flash_speed + v_phase);
	float wave_b = sin(TIME * flash_speed * 0.47 + v_phase * 1.7) * 0.18;
	float flash_t = clamp(wave_a * 0.5 + 0.5 + wave_b, 0.0, 1.0);
	flash_t = flash_t * flash_t * (3.0 - 2.0 * flash_t);
	float flash = mix(flash_min, flash_max, flash_t);

	if (outside) {
		COLOR = border_color;
		COLOR.rgb *= flash;
	} else {
		vec2 animated_pos = v_static_pos * breathe + bob;
		vec2 uv = animated_pos / tex_size + vec2(0.5);
		vec4 col = texture(TEXTURE, uv);
		col.rgb *= flash;
		COLOR = col;
	}
}
