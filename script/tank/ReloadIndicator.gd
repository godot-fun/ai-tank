extends Node2D
class_name ReloadIndicator

const RADIUS := 13.0
const LINE_WIDTH := 3.0

var progress := 0.0


func _ready() -> void:
	top_level = true
	z_index = 10
	visible = false
	pass


func update_reload(world_position: Vector2, remaining: float, total: float) -> void:
	global_position = world_position

	var is_reloading : = remaining > 0.0 and total > 0.0
	visible = is_reloading
	if not is_reloading:
		return

	var new_progress := clampf(1.0 - remaining / total, 0.0, 1.0)
	if not is_equal_approx(progress, new_progress):
		progress = new_progress
		queue_redraw()
	pass


func _draw() -> void:
	draw_circle(
		Vector2.ZERO,
		RADIUS,
		Color(0.0, 0.0, 0.0, 0.55),
	)
	draw_arc(
		Vector2.ZERO,
		RADIUS,
		0.0,
		TAU,
		48,
		Color(0.35, 0.35, 0.35, 0.9),
		LINE_WIDTH,
		true,
	)

	var start_angle := -PI / 2.0
	draw_arc(
		Vector2.ZERO,
		RADIUS,
		start_angle,
		start_angle + TAU * progress,
		48,
		Color(0.55, 0.92, 0.45),
		LINE_WIDTH,
		true,
	)
	pass
