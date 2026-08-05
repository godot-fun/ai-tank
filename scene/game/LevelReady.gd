extends Control

const BATTLE_SCENE_PATH := "res://scene/game/BattleMap.tscn"
const COUNTDOWN_SECONDS := 5
const TANK_ICON_SIZE := 72.0
const BUFF_ICON_SIZE := 48.0
const KILL_COL_WIDTH := 140.0
const BUFF_COL_WIDTH := 72.0

## 会进入 buff_map 的可叠加 buff，按枚举顺序作为固定列
const DISPLAY_BUFF_TYPES: Array[int] = [
	IBuff.BuffType.BULLET_SIZE,
	IBuff.BuffType.BULLET_SPEED,
	IBuff.BuffType.BULLET_FIRE_INTERVAL,
	IBuff.BuffType.TANK_SPEED,
	IBuff.BuffType.TANK_HP,
	IBuff.BuffType.TANK_RESPAWN,
	IBuff.BuffType.TANK_SIZE,
]

@onready var level_label: Label = $CenterContainer/VBox/LevelLabel
@onready var tank_stats: VBoxContainer = $CenterContainer/VBox/TankStats
@onready var tap_prompt: Label = $TapPrompt

var transitioning := false


func _ready() -> void:
	set_process_input(true)
	level_label.text = "第 %d 关" % (BattleProgress.level + 1)
	populate_tank_stats()
	Audios.play_sfx(AudioConfig.STAGE_START)
	start_countdown()
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
	tank_stats.add_child(make_header_row())
	for tank_id: int in BuffManager.get_player_tank_ids():
		tank_stats.add_child(make_tank_row(TankConfig.tank_datas[tank_id]))
	pass


func should_show_stats() -> bool:
	if not BuffManager.enemy_kill_counts.is_empty():
		return true
	for tank_id: int in BuffManager.get_player_tank_ids():
		if BuffManager.buff_map[tank_id].buffs.size() > 0:
			return true
	return false


func make_header_row() -> Control:
	var row := HBoxContainer.new()
	row.name = "HeaderRow"
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 16)

	var tank_spacer := Control.new()
	tank_spacer.name = "TankSpacer"
	tank_spacer.custom_minimum_size = Vector2(TANK_ICON_SIZE, BUFF_ICON_SIZE)
	row.add_child(tank_spacer)

	var kill_header := Label.new()
	kill_header.name = "KillHeader"
	kill_header.text = "击杀"
	kill_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kill_header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	kill_header.custom_minimum_size = Vector2(KILL_COL_WIDTH, BUFF_ICON_SIZE)
	kill_header.add_theme_font_size_override("font_size", 28)
	kill_header.add_theme_color_override("font_color", Color(0.75, 0.8, 0.88, 1))
	row.add_child(kill_header)

	for buff_type: int in DISPLAY_BUFF_TYPES:
		row.add_child(make_buff_header_cell(buff_type))

	return row


func make_buff_header_cell(buff_type: int) -> Control:
	var cell := CenterContainer.new()
	cell.name = StringUtils.format("BuffHeader_{}", IBuff.BuffType.keys()[buff_type])
	cell.custom_minimum_size = Vector2(BUFF_COL_WIDTH, BUFF_ICON_SIZE)
	cell.mouse_filter = Control.MOUSE_FILTER_STOP
	cell.tooltip_text = get_buff_description(buff_type)

	var resource := get_buff_resource(buff_type)
	if !resource.is_empty():
		var icon := TextureRect.new()
		icon.name = "BuffIcon"
		icon.texture = load(resource)
		icon.custom_minimum_size = Vector2(BUFF_ICON_SIZE, BUFF_ICON_SIZE)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(icon)

	return cell


func make_tank_row(tank_data: TankConfig.TankData) -> Control:
	var row := HBoxContainer.new()
	row.name = StringUtils.format("TankRow_{}", tank_data.id)
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 16)

	var tank_resource := BuffManager.appearance_tank_resource(tank_data.id, tank_data.tank_resource)
	var tank_icon := TextureRect.new()
	tank_icon.name = "TankIcon"
	tank_icon.texture = load(tank_resource)
	tank_icon.custom_minimum_size = Vector2(TANK_ICON_SIZE, TANK_ICON_SIZE)
	tank_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tank_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(tank_icon)

	var kills: int = 0
	if BuffManager.enemy_kill_counts.has(tank_data.id):
		kills = BuffManager.enemy_kill_counts[tank_data.id]
	var kill_label := Label.new()
	kill_label.name = "KillCount"
	kill_label.text = "x%d" % kills
	kill_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kill_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	kill_label.custom_minimum_size = Vector2(KILL_COL_WIDTH, TANK_ICON_SIZE)
	kill_label.add_theme_font_size_override("font_size", 32)
	kill_label.add_theme_color_override("font_color", Color(0.92, 0.94, 0.98, 1))
	row.add_child(kill_label)

	var buff_counts := get_buff_type_counts(tank_data.id)
	for buff_type: int in DISPLAY_BUFF_TYPES:
		var count: int = 0
		if buff_counts.has(buff_type):
			count = buff_counts[buff_type]
		row.add_child(make_buff_count_cell(buff_type, count))

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


func make_buff_count_cell(buff_type: int, count: int) -> Control:
	var cell := CenterContainer.new()
	cell.name = StringUtils.format("BuffCount_{}", IBuff.BuffType.keys()[buff_type])
	cell.custom_minimum_size = Vector2(BUFF_COL_WIDTH, TANK_ICON_SIZE)
	cell.mouse_filter = Control.MOUSE_FILTER_STOP
	cell.tooltip_text = get_buff_description(buff_type)

	var label := Label.new()
	label.name = "CountLabel"
	label.text = str(count) if count > 0 else "-"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)
	if count > 0:
		label.add_theme_color_override("font_color", Color(0.92, 0.94, 0.98, 1))
	else:
		label.add_theme_color_override("font_color", Color(0.55, 0.58, 0.65, 1))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(label)

	return cell


func get_buff_resource(buff_type: int) -> String:
	return BuffConfig.buff_datas[buff_type].buff_resource


func get_buff_description(buff_type: int) -> String:
	match buff_type:
		IBuff.BuffType.BULLET_SIZE:
			return "增大子弹体积，并提升子弹伤害"
		IBuff.BuffType.BULLET_SPEED:
			return "提升子弹飞行速度"
		IBuff.BuffType.BULLET_FIRE_INTERVAL:
			return "缩短开火间隔，提升射速"
		IBuff.BuffType.TANK_SPEED:
			return "提升坦克移动速度"
		IBuff.BuffType.TANK_HP:
			return "提升坦克生命值"
		IBuff.BuffType.TANK_RESPAWN:
			return "缩短坦克复活等待时间"
		IBuff.BuffType.TANK_SIZE:
			return "缩小坦克体积，更易躲避攻击"
		IBuff.BuffType.FREEZE:
			return "冻结全场敌人一段时间"
		IBuff.BuffType.AIR_STRIKE:
			return "呼叫空袭，对场上敌人造成伤害"
		IBuff.BuffType.EAGLE_STEEL:
			return "将基地周围砖墙临时变为钢墙"
		_:
			return ""


func start_countdown() -> void:
	tap_prompt.visible = true
	for remaining: int in range(COUNTDOWN_SECONDS, 0, -1):
		if transitioning:
			return
		tap_prompt.text = "READY %d" % remaining
		tap_prompt.modulate.a = 1.0
		var pulse_tween := create_tween()
		pulse_tween.tween_property(tap_prompt, "modulate:a", 0.45, 0.9)
		await get_tree().create_timer(1.0).timeout
	if transitioning:
		return
	tap_prompt.text = "GO!"
	tap_prompt.modulate.a = 1.0
	await get_tree().create_timer(0.6).timeout
	if transitioning:
		return
	go_to_battle()
	pass


func _input(event: InputEvent) -> void:
	if event.is_pressed() and not event.is_echo():
		get_viewport().set_input_as_handled()
		set_process_input(false)
		on_screen_tapped()
	pass


func on_screen_tapped() -> void:
	Audios.play_sfx(AudioConfig.UI_CONFIRM)
	go_to_battle()
	pass


func go_to_battle() -> void:
	if transitioning:
		return
	transitioning = true
	set_process_input(false)
	await SceneHelper.async_change_scene_to_file(BATTLE_SCENE_PATH)
	pass
