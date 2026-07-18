extends Node2D
class_name RespawnCountdown

const RADIUS := 28.0
const LINE_WIDTH := 3.0
const FONT_SIZE := 22

var duration := 0.0
var elapsed := 0.0
var last_display := -1
var label: Label


static func spawn(world_position: Vector2, duration: float, parent: Node) -> void:
	if parent == null or duration <= 0.0:
		return

	var countdown := RespawnCountdown.new()
	countdown.duration = duration
	countdown.global_position = world_position
	parent.add_child(countdown)
	pass


func _ready() -> void:
	top_level = true
	z_index = 2048
	setup_label()
	update_display(int(ceil(duration)))
	set_process(true)
	pass


func setup_label() -> void:
	label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", Color(0.55, 0.92, 0.45))

	var size := Vector2(RADIUS * 2.0, RADIUS * 2.0)
	label.custom_minimum_size = size
	label.size = size
	label.position = -size * 0.5
	label.pivot_offset = size * 0.5
	add_child(label)
	pass


func _process(delta: float) -> void:
	elapsed += delta
	var remaining := duration - elapsed
	if remaining <= 0.0:
		queue_free()
		return

	var display := int(ceil(remaining))
	if display != last_display:
		last_display = display
		update_display(display)
		play_tick_animation()

	queue_redraw()
	pass


func update_display(value: int) -> void:
	if label != null:
		label.text = str(value)
	pass


func play_tick_animation() -> void:
	if label == null:
		return

	label.scale = Vector2(1.35, 1.35)
	var tween := create_tween()
	tween.tween_property(label, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
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

	var progress := clampf(1.0 - elapsed / duration, 0.0, 1.0)
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
