shader_type canvas_item;

// move_amount: 0 = idle, 1 = moving
uniform float move_amount : hint_range(0.0, 1.0) = 0.0;
// Screen-pixel shake amplitude; divided by world_scale in vertex().
uniform float shake_strength : hint_range(0.0, 16.0) = 2.5;
uniform float shake_speed : hint_range(1.0, 80.0) = 36.0;
uniform float rotation_shake : hint_range(0.0, 0.2) = 0.018;
uniform float world_scale : hint_range(0.01, 4.0) = 1.0;

void vertex() {
	if (move_amount >= 0.001) {
		float local_scale = max(world_scale, 0.001);
		float t = TIME * shake_speed;
		vec2 jitter = vec2(
			sin(t * 2.17) * cos(t * 1.83),
			cos(t * 1.91) * sin(t * 2.41)
		) * (shake_strength / local_scale) * move_amount;

		float angle = sin(t * 3.7) * rotation_shake * move_amount;
		float c = cos(angle);
		float s = sin(angle);
		vec2 rotated = vec2(
			VERTEX.x * c - VERTEX.y * s,
			VERTEX.x * s + VERTEX.y * c
		);

		float pulse = 1.0 + sin(t * 4.2) * 0.006 * move_amount;
		VERTEX = rotated * pulse + jitter;
	}
}
