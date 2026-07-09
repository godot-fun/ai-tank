shader_type canvas_item;

uniform float flash_speed : hint_range(0.5, 10.0) = 3.0;
uniform float flash_min : hint_range(0.0, 1.0) = 0.5;
uniform float flash_max : hint_range(0.0, 2.0) = 1.2;
uniform float border_pixels : hint_range(1.0, 128.0) = 6.0;
// NES palette $30 — helmet invincibility / classic pickup blink white (#FCFCFC).
uniform vec4 border_color : source_color = vec4(0.988, 0.988, 0.988, 1.0);

varying vec2 v_local_pos;

void vertex() {
	vec2 dir = sign(VERTEX);
	VERTEX += dir * border_pixels;
	v_local_pos = VERTEX;
}

void fragment() {
	vec2 tex_half = 0.5 / TEXTURE_PIXEL_SIZE;
	vec2 tex_size = 1.0 / TEXTURE_PIXEL_SIZE;
	bool outside = abs(v_local_pos.x) > tex_half.x || abs(v_local_pos.y) > tex_half.y;

	float flash = mix(flash_min, flash_max, sin(TIME * flash_speed) * 0.5 + 0.5);

	if (outside) {
		COLOR = border_color;
		COLOR.rgb *= flash;
	} else {
		vec2 uv = v_local_pos / tex_size + vec2(0.5);
		vec4 col = texture(TEXTURE, uv);
		col.rgb *= flash;
		COLOR = col;
	}
}
