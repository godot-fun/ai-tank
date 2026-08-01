extends Node2D
class_name StageClearEffect

const SCENE := "res://scene/effects/StageClearEffect.tscn"
const BANNER_DURATION := 2.0
const HOLD_AFTER_ANIM := 3.0
const POPUP_DURATION := 0.55
const POPUP_START_OFFSET := 160.0

var _particles: Array[GPUParticles2D] = []
var _overlay_layer: CanvasLayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 4096
	await get_tree().process_frame
	await play_celebration()
	queue_free()
	pass


func play_celebration() -> void:
	var map_size := Vector2(
		TileConfig.MAP_GRID_WIDTH * TileConfig.TILE_SIZE,
		TileConfig.MAP_GRID_HEIGHT * TileConfig.TILE_SIZE,
	)
	var target_center := map_size * 0.5
	var start_pos := Vector2(target_center.x, map_size.y + POPUP_START_OFFSET)

	_add_dim_overlay()

	var banner_host := Node2D.new()
	banner_host.name = "BannerHost"
	banner_host.position = start_pos
	add_child(banner_host)

	_setup_particles(banner_host)

	var popup_tween := create_tween()
	popup_tween.tween_property(banner_host, "position", target_center, POPUP_DURATION) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_start_particles()
	_spawn_banner()
	await popup_tween.finished
	await get_tree().create_timer(BANNER_DURATION, true).timeout
	await get_tree().create_timer(HOLD_AFTER_ANIM, true).timeout
	_stop_particles()
	pass


func _add_dim_overlay() -> void:
	_overlay_layer = CanvasLayer.new()
	_overlay_layer.name = "DimOverlay"
	_overlay_layer.layer = 90
	add_child(_overlay_layer)

	var dim := ColorRect.new()
	dim.name = "DimRect"
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.color = Color(0.0, 0.0, 0.0, 0.35)
	_overlay_layer.add_child(dim)
	pass


func _spawn_banner() -> void:
	if _overlay_layer == null:
		return

	var label := Label.new()
	label.name = "BannerLabel"
	label.text = "STAGE CLEAR"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 96)
	label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.35))
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.offset_left = -320.0
	label.offset_top = -60.0
	label.offset_right = 320.0
	label.offset_bottom = 60.0
	label.modulate.a = 0.0
	label.scale = Vector2(0.5, 0.5)
	label.pivot_offset = Vector2(320.0, 60.0)
	_overlay_layer.add_child(label)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "modulate:a", 1.0, 0.4)
	tween.tween_property(label, "scale", Vector2.ONE, 0.6) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pass


func _setup_particles(host: Node2D) -> void:
	var offsets: Array[Vector2] = [
		Vector2(-260.0, -100.0),
		Vector2(260.0, -100.0),
		Vector2(-280.0, 80.0),
		Vector2(280.0, 80.0),
		Vector2(0.0, -170.0),
		Vector2(0.0, 150.0),
		Vector2(-140.0, 0.0),
		Vector2(140.0, 0.0),
	]
	var colors: Array[Color] = [
		Color(1.0, 0.88, 0.25),
		Color(1.0, 0.55, 0.15),
		Color(1.0, 0.95, 0.55),
		Color(0.95, 0.35, 0.55),
		Color(0.55, 0.9, 1.0),
		Color(0.75, 1.0, 0.45),
		Color(1.0, 0.88, 0.25),
		Color(1.0, 0.55, 0.15),
	]
	for i in offsets.size():
		var particles := _create_sparkle_particles(offsets[i], colors[i])
		host.add_child(particles)
		_particles.append(particles)
	pass


func _create_sparkle_particles(position: Vector2, color: Color) -> GPUParticles2D:
	var particles := GPUParticles2D.new()
	particles.name = "SparkleParticles"
	particles.position = position
	particles.amount = 24
	particles.lifetime = 1.4
	particles.preprocess = 0.2
	particles.explosiveness = 0.15
	particles.randomness = 0.6
	particles.texture = _create_particle_texture()
	particles.process_material = _create_particle_material(color)
	return particles


func _create_particle_texture() -> Texture2D:
	var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for x in range(8):
		for y in range(8):
			var dist := Vector2(x - 3.5, y - 3.5).length()
			var alpha := clampf(1.0 - dist / 4.0, 0.0, 1.0)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(image)


func _create_particle_material(color: Color) -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.particle_flag_disable_z = true
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 18.0
	material.direction = Vector3(0.0, -1.0, 0.0)
	material.spread = 180.0
	material.initial_velocity_min = 60.0
	material.initial_velocity_max = 140.0
	material.gravity = Vector3(0.0, 80.0, 0.0)
	material.scale_min = 2.0
	material.scale_max = 5.0
	material.color = color
	return material


func _start_particles() -> void:
	for particles in _particles:
		particles.emitting = true
	pass


func _stop_particles() -> void:
	for particles in _particles:
		particles.emitting = false
	pass
