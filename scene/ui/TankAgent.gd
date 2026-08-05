extends Control

const HOME_SCENE := "res://scene/Home.tscn"
const TANK_ICON_SIZE := 72.0

@onready var form: VBoxContainer = $Margin/VBox/Scroll/Form
@onready var status_label: Label = $Margin/VBox/StatusLabel
@onready var back_button: Button = $BackButton

var editors: Dictionary = {}
var generate_buttons: Dictionary = {}
var generating := false


func _ready() -> void:
	back_button.pressed.connect(on_back_pressed)
	back_button.mouse_entered.connect(on_button_hover)
	build_form()
	refresh_status()
	pass


func _exit_tree() -> void:
	if generating:
		return
	persist_editors(true)
	pass


func build_form() -> void:
	for child in form.get_children():
		child.queue_free()
	editors.clear()
	generate_buttons.clear()

	for key: String in TankAgentManager.AGENT_TANK_IDS:
		var tank_data := TankAgentManager.tank_data_for_key(key)
		var row := VBoxContainer.new()
		row.name = StringUtils.format("Row_{}", key)
		row.add_theme_constant_override("separation", 8)

		var header := HBoxContainer.new()
		header.add_theme_constant_override("separation", 16)
		header.alignment = BoxContainer.ALIGNMENT_BEGIN

		var icon := TextureRect.new()
		icon.name = "TankIcon"
		icon.texture = load(tank_data.tank_resource)
		icon.custom_minimum_size = Vector2(TANK_ICON_SIZE, TANK_ICON_SIZE)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.tooltip_text = key
		header.add_child(icon)

		var generate_button := Button.new()
		generate_button.name = "GenerateButton"
		generate_button.text = "生成策略"
		generate_button.custom_minimum_size = Vector2(160, 56)
		generate_button.add_theme_font_size_override("font_size", 24)
		generate_button.disabled = generating
		generate_button.mouse_entered.connect(on_button_hover)
		generate_button.pressed.connect(on_generate_one_pressed.bind(key))
		header.add_child(generate_button)
		row.add_child(header)

		var strategy := TankAgentManager.get_strategy(key)
		var editor := TextEdit.new()
		editor.name = "Editor"
		editor.custom_minimum_size = Vector2(0, 120)
		editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		if TankAgentManager.has_generated_script(key) and !StringUtils.is_blank(strategy):
			editor.placeholder_text = strategy
		else:
			editor.placeholder_text = "使用默认脚本"
		editor.text = strategy
		editor.add_theme_font_size_override("font_size", 22)
		row.add_child(editor)

		form.add_child(row)
		editors[key] = editor
		generate_buttons[key] = generate_button
	pass


func refresh_status() -> void:
	var generated := 0
	var filled := 0
	for key: String in TankAgentManager.AGENT_TANK_IDS:
		if !StringUtils.is_blank(TankAgentManager.get_strategy(key)):
			filled += 1
		if TankAgentManager.has_generated_script(key):
			generated += 1
	var total := TankAgentManager.AGENT_TANK_IDS.size()
	status_label.text = "策略 %d / %d，已生成 %d / %d（有生成代码则游戏优先使用）" % [
		filled, total, generated, total
	]
	pass


func persist_editors(clear_changed_scripts: bool) -> void:
	if editors.is_empty():
		return
	for key: String in TankAgentManager.AGENT_TANK_IDS:
		if !editors.has(key):
			continue
		var editor: TextEdit = editors[key]
		var new_text := editor.text.strip_edges()
		var old_text := TankAgentManager.get_strategy(key)
		TankAgentManager.set_strategy(key, new_text)
		if clear_changed_scripts and old_text != new_text:
			TankAgentManager.delete_generated_script(key)
	TankAgentManager.save_strategies()
	pass


func set_busy(busy: bool) -> void:
	generating = busy
	back_button.disabled = busy
	for key: String in generate_buttons:
		var button: Button = generate_buttons[key]
		button.disabled = busy
	pass


func on_button_hover() -> void:
	Audios.play_sfx(AudioConfig.UI_SELECT)
	pass


func on_generate_one_pressed(key: String) -> void:
	if RateLimitUtils.limit_second_1() or generating:
		return
	Audios.play_sfx(AudioConfig.UI_CONFIRM)
	persist_editors(false)

	var strategy := TankAgentManager.get_strategy(key)
	if StringUtils.is_blank(strategy):
		Alert.alert("请先填写策略文本", Colors.warning)
		return

	set_busy(true)
	status_label.text = StringUtils.format("正在生成 {} 的策略代码…", key)
	Alert.alert(StringUtils.format("开始生成 {}", key), Colors.info)

	var ok := await TankAgentManager.async_generate_one(key)
	set_busy(false)
	build_form()
	refresh_status()

	if ok:
		Alert.alert(StringUtils.format("{} 策略已生成", key), Colors.success)
	else:
		Alert.alert(StringUtils.format("{} 策略生成失败", key), Colors.error)
	pass


func on_back_pressed() -> void:
	if generating:
		return
	Audios.play_sfx(AudioConfig.UI_SELECT)
	persist_editors(true)
	await SceneHelper.async_change_scene_to_file(HOME_SCENE)
	pass
