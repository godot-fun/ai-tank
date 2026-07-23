extends Control

const BATTLE_SCENE_PATH := "res://scene/map/BattleMap.tscn"
const TANK_ICON_SIZE := 72.0
const BUFF_ICON_SIZE := 48.0

@onready var level_label: Label = $CenterContainer/VBox/LevelLabel
@onready var tank_stats: VBoxContainer = $CenterContainer/VBox/TankStats
@onready var tap_prompt: Label = $TapPrompt


func _ready() -> void:
	set_process_input(false)
	level_label.text = "第 %d 关" % (BattleProgress.level + 1)
	populate_tank_stats()
	show_tap_prompt()
	Audios.play_sfx(AudioConfig.STAGE_START)
	pass


func populate_tank_stats() -> void:
	var stats_title: Label = $CenterContainer/VBox/StatsTitle
	var show_stats := should_show_stats()
	stats_title.visible = show_stats
	tank_stats.visible = show_stats
	for child in tank_stats.get_children():
		child.queue_free()
	if !show_stats:
		return
	for tank_data: TankConfig.TankData in get_brief_tanks():
		tank_stats.add_child(make_tank_row(tank_data))
	pass


func should_show_stats() -> bool:
	if not BuffManager.enemy_kill_counts.is_empty():
		return true
	for tank_data: TankConfig.TankData in get_brief_tanks():
		if !BuffManager.buff_map.has(tank_data.id):
			continue
		if BuffManager.buff_map[tank_data.id].buffs.size() > 0:
			return true
	return false


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


func make_tank_row(tank_data: TankConfig.TankData) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 16)

	var tank_icon := TextureRect.new()
	tank_icon.texture = load(tank_data.tank_resource)
	tank_icon.custom_minimum_size = Vector2(TANK_ICON_SIZE, TANK_ICON_SIZE)
	tank_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tank_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(tank_icon)

	var kills: int = 0
	if BuffManager.enemy_kill_counts.has(tank_data.id):
		kills = BuffManager.enemy_kill_counts[tank_data.id]
	var kill_label := Label.new()
	kill_label.text = "击杀 x%d" % kills
	kill_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	kill_label.add_theme_font_size_override("font_size", 32)
	kill_label.add_theme_color_override("font_color", Color(0.92, 0.94, 0.98, 1))
	row.add_child(kill_label)

	var buff_row := HBoxContainer.new()
	buff_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	buff_row.add_theme_constant_override("separation", 12)
	var buff_counts := get_buff_type_counts(tank_data.id)
	for buff_type: int in buff_counts:
		buff_row.add_child(make_buff_entry(buff_type, buff_counts[buff_type]))
	row.add_child(buff_row)

	return row


func get_buff_type_counts(tank_id: int) -> Dictionary[int, int]:
	var counts: Dictionary[int, int] = {}
	if !BuffManager.buff_map.has(tank_id):
		return counts
	for buff: IBuff in BuffManager.buff_map[tank_id].buffs:
		var buff_type: int = buff.type()
		if counts.has(buff_type):
			counts[buff_type] = counts[buff_type] + 1
		else:
			counts[buff_type] = 1
	return counts


func make_buff_entry(buff_type: int, count: int) -> Control:
	var entry := HBoxContainer.new()
	entry.alignment = BoxContainer.ALIGNMENT_CENTER
	entry.add_theme_constant_override("separation", 4)

	var resource := get_buff_resource(buff_type)
	if !resource.is_empty():
		var icon := TextureRect.new()
		icon.texture = load(resource)
		icon.custom_minimum_size = Vector2(BUFF_ICON_SIZE, BUFF_ICON_SIZE)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		entry.add_child(icon)

	var label := Label.new()
	label.text = "x%d" % count
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95, 1))
	entry.add_child(label)

	return entry


func get_buff_resource(buff_type: int) -> String:
	for id: int in BuffConfig.buff_datas:
		var data := BuffConfig.buff_datas[id]
		if data.buff == buff_type:
			return data.buff_resource
	return ""


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
