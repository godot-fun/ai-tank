extends Node2D
class_name GameOverEffect

enum FailReason {
	EAGLE_DESTROYED,
	TIME_UP,
}

const SCENE := "res://scene/effects/GameOverEffect.tscn"
const HOME_SCENE_PATH := "res://scene/Home.tscn"
const LEVEL_READY_SCENE_PATH := "res://scene/game/LevelReady.tscn"
const BANNER_DURATION := 2.0
const AI_RETRY_COUNTDOWN := 5
const DROP_DURATION := 0.7
const DROP_START_OFFSET := 200.0

var fail_reason := FailReason.TIME_UP

var _particles: Array[GPUParticles2D] = []
var _overlay_layer: CanvasLayer
var _buttons: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 4096
	await get_tree().process_frame
	await play_defeat()
	pass


func play_defeat() -> void:
	var map_size := Vector2(
		TileConfig.MAP_GRID_WIDTH * TileConfig.TILE_SIZE,
		TileConfig.MAP_GRID_HEIGHT * TileConfig.TILE_SIZE,
	)
	var target_center := map_size * 0.5
	var start_pos := Vector2(target_center.x, -DROP_START_OFFSET)

	_add_dim_overlay()

	var banner_host := Node2D.new()
	banner_host.position = start_pos
	add_child(banner_host)

	_setup_particles(banner_host)

	var drop_tween := create_tween()
	drop_tween.tween_property(banner_host, "position", target_center, DROP_DURATION) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	_start_particles()
	_spawn_banner()
	await drop_tween.finished
	await get_tree().create_timer(BANNER_DURATION, true).timeout
	_stop_particles()
	_spawn_action_buttons()
	if BattleProgress.play_mode == BattleProgress.PlayMode.AI:
		await _auto_retry_after_countdown()
	pass


func _add_dim_overlay() -> void:
	_overlay_layer = CanvasLayer.new()
	_overlay_layer.layer = 90
	add_child(_overlay_layer)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.color = Color(0.12, 0.0, 0.0, 0.0)
	_overlay_layer.add_child(dim)

	var tween := create_tween()
	tween.tween_property(dim, "color", Color(0.12, 0.0, 0.0, 0.58), 0.5)
	pass


func _spawn_banner() -> void:
	var label := Label.new()
	label.text = _get_banner_text()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 80)
	label.add_theme_color_override("font_color", Color(0.92, 0.22, 0.18))
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.offset_left = -320.0
	label.offset_top = -60.0
	label.offset_right = 320.0
	label.offset_bottom = 60.0
	label.modulate.a = 0.0
	label.scale = Vector2(1.2, 1.2)
	label.pivot_offset = Vector2(320.0, 60.0)
	_overlay_layer.add_child(label)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "modulate:a", 1.0, 0.45)
	tween.tween_property(label, "scale", Vector2.ONE, 0.55) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	pass


func _spawn_action_buttons() -> void:
	_buttons = VBoxContainer.new()
	_buttons.set_anchors_preset(Control.PRESET_CENTER)
	_buttons.offset_left = -140.0
	_buttons.offset_top = 80.0
	_buttons.offset_right = 140.0
	_buttons.offset_bottom = 240.0
	_buttons.add_theme_constant_override("separation", 16)
	_buttons.modulate.a = 0.0
	_overlay_layer.add_child(_buttons)

	_add_button("重试", _on_retry_pressed)
	_add_button("回到主界面", _on_home_pressed)
	create_tween().tween_property(_buttons, "modulate:a", 1.0, 0.4)
	pass


func _add_button(text: String, on_pressed: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(280.0, 64.0)
	button.add_theme_font_size_override("font_size", 32)
	button.pressed.connect(on_pressed)
	button.mouse_entered.connect(func() -> void: Audios.play_sfx(AudioConfig.UI_SELECT))
	_buttons.add_child(button)
	pass


func _auto_retry_after_countdown() -> void:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", Color(0.92, 0.94, 0.98))
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.offset_left = -360.0
	label.offset_top = 250.0
	label.offset_right = 360.0
	label.offset_bottom = 310.0
	_overlay_layer.add_child(label)

	var remaining := AI_RETRY_COUNTDOWN
	while remaining > 0:
		label.text = "AI模式下自动重试 %d" % remaining
		await get_tree().create_timer(1.0, true).timeout
		remaining -= 1

	_on_retry_pressed()
	pass


func _on_retry_pressed() -> void:
	_buttons.visible = false
	Audios.play_sfx(AudioConfig.UI_CONFIRM)
	BuffManager.remove_current_level_buffs()
	await SceneHelper.async_change_scene_to_file(LEVEL_READY_SCENE_PATH)
	pass


func _on_home_pressed() -> void:
	_buttons.visible = false
	Audios.play_sfx(AudioConfig.UI_CONFIRM)
	await SceneHelper.async_change_scene_to_file(HOME_SCENE_PATH)
	pass


func _setup_particles(host: Node2D) -> void:
	var offsets: Array[Vector2] = [
		Vector2(-220.0, -80.0),
		Vector2(220.0, -80.0),
		Vector2(-240.0, 60.0),
		Vector2(240.0, 60.0),
		Vector2(0.0, -140.0),
		Vector2(0.0, 120.0),
	]
	var colors: Array[Color] = [
		Color(0.55, 0.12, 0.1, 0.9),
		Color(0.35, 0.08, 0.08, 0.85),
		Color(0.2, 0.2, 0.22, 0.8),
		Color(0.45, 0.15, 0.1, 0.9),
		Color(0.3, 0.3, 0.32, 0.75),
		Color(0.55, 0.12, 0.1, 0.9),
	]
	for i in offsets.size():
		var particles := _create_smoke_particles(offsets[i], colors[i])
		host.add_child(particles)
		_particles.append(particles)
	pass


func _create_smoke_particles(position: Vector2, color: Color) -> GPUParticles2D:
	var particles := GPUParticles2D.new()
	particles.position = position
	particles.amount = 18
	particles.lifetime = 2.0
	particles.preprocess = 0.1
	particles.explosiveness = 0.05
	particles.randomness = 0.75
	particles.texture = _create_particle_texture()
	particles.process_material = _create_particle_material(color)
	return particles


func _create_particle_texture() -> Texture2D:
	var image := Image.create(10, 10, false, Image.FORMAT_RGBA8)
	for x in range(10):
		for y in range(10):
			var dist := Vector2(x - 4.5, y - 4.5).length()
			var alpha := clampf(1.0 - dist / 5.0, 0.0, 1.0)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha * 0.7))
	return ImageTexture.create_from_image(image)


func _create_particle_material(color: Color) -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.particle_flag_disable_z = true
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 24.0
	material.direction = Vector3(0.0, 1.0, 0.0)
	material.spread = 120.0
	material.initial_velocity_min = 20.0
	material.initial_velocity_max = 55.0
	material.gravity = Vector3(0.0, 30.0, 0.0)
	material.scale_min = 3.0
	material.scale_max = 7.0
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


func _get_banner_text() -> String:
	match fail_reason:
		FailReason.EAGLE_DESTROYED:
			return "基地被摧毁"
		FailReason.TIME_UP:
			return "时间到"
	return "GAME OVER"
	pass
