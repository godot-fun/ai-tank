extends Control

const BATTLE_SCENE_PATH := "res://scene/map/BattleMap.tscn"
const TANK_ICON_SIZE := 96.0

@onready var level_label: Label = $CenterContainer/VBox/LevelLabel
@onready var kill_stats: HBoxContainer = $CenterContainer/VBox/KillStats
@onready var tap_prompt: Label = $TapPrompt


func _ready() -> void:
	set_process_input(false)
	level_label.text = "第 %d 关" % (BattleProgress.level + 1)
	populate_kill_stats()
	show_tap_prompt()
	Audios.play_sfx(AudioConfig.STAGE_START)
	pass


func populate_kill_stats() -> void:
	var kill_title: Label = $CenterContainer/VBox/KillTitle
	var has_kills := not BuffManager.enemy_kill_counts.is_empty()
	kill_title.visible = has_kills
	kill_stats.visible = has_kills
	for child in kill_stats.get_children():
		child.queue_free()
	if !has_kills:
		return
	for tank_data: TankConfig.TankData in get_brief_tanks():
		kill_stats.add_child(make_kill_entry(tank_data))
	pass


func get_brief_tanks() -> Array[TankConfig.TankData]:
	var tanks: Array[TankConfig.TankData] = [
		TankConfig.my_tank,
		TankConfig.partner_tank_1,
	]
	var level := BattleProgress.level
	if level >= 3:
		tanks.append(TankConfig.partner_tank_2)
	if level >= 8:
		tanks.append(TankConfig.partner_tank_3)
	if level >= 13:
		tanks.append(TankConfig.partner_tank_4)
	if level >= 18:
		tanks.append(TankConfig.partner_tank_5)
	if level >= 23:
		tanks.append(TankConfig.partner_tank_6)
	return tanks


func make_kill_entry(tank_data: TankConfig.TankData) -> Control:
	var entry := VBoxContainer.new()
	entry.alignment = BoxContainer.ALIGNMENT_CENTER
	entry.add_theme_constant_override("separation", 8)

	var icon := TextureRect.new()
	icon.texture = load(tank_data.tank_resource)
	icon.custom_minimum_size = Vector2(TANK_ICON_SIZE, TANK_ICON_SIZE)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	entry.add_child(icon)

	var kills: int = 0
	if BuffManager.enemy_kill_counts.has(tank_data.id):
		kills = BuffManager.enemy_kill_counts[tank_data.id]
	var label := Label.new()
	label.text = "x%d" % kills
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", Color(0.92, 0.94, 0.98, 1))
	entry.add_child(label)

	return entry


func show_tap_prompt() -> void:
	tap_prompt.modulate.a = 0.0
	tap_prompt.visible = true

	var fade_tween := create_tween()
	fade_tween.tween_property(tap_prompt, "modulate:a", 1.0, 0.5)
	await fade_tween.finished

	set_process_input(true)

	var pulse_tween := create_tween().set_loops()
	pulse_tween.tween_property(tap_prompt, "modulate:a", 0.4, 0.8)
	pulse_tween.tween_property(tap_prompt, "modulate:a", 1.0, 0.8)
	pass


func _input(event: InputEvent) -> void:
	if event.is_pressed() and not event.is_echo():
		get_viewport().set_input_as_handled()
		set_process_input(false)
		on_screen_tapped()
	pass


func on_screen_tapped() -> void:
	Audios.play_sfx(AudioConfig.UI_CONFIRM)
	await SceneHelper.async_change_scene_to_file(BATTLE_SCENE_PATH)
	pass
