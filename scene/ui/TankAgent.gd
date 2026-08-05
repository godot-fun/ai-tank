extends Control

const HOME_SCENE := "res://scene/Home.tscn"

@onready var form: VBoxContainer = $Margin/VBox/Scroll/Form
@onready var status_label: Label = $Margin/VBox/StatusLabel
@onready var save_button: Button = $Margin/VBox/ButtonRow/SaveButton
@onready var generate_button: Button = $Margin/VBox/ButtonRow/GenerateButton
@onready var back_button: Button = $Margin/VBox/ButtonRow/BackButton

var editors: Dictionary = {}
var generating := false


func _ready() -> void:
	save_button.pressed.connect(on_save_pressed)
	generate_button.pressed.connect(on_generate_pressed)
	back_button.pressed.connect(on_back_pressed)
	save_button.mouse_entered.connect(on_button_hover)
	generate_button.mouse_entered.connect(on_button_hover)
	back_button.mouse_entered.connect(on_button_hover)
	build_form()
	refresh_status()
	pass


func build_form() -> void:
	for child in form.get_children():
		child.queue_free()
	editors.clear()

	for key: String in TankAgentManager.AGENT_TANK_IDS:
		var row := VBoxContainer.new()
		row.name = StringUtils.format("Row_{}", key)
		row.add_theme_constant_override("separation", 8)

		var header := HBoxContainer.new()
		header.add_theme_constant_override("separation", 12)

		var title := Label.new()
		title.text = key
		title.add_theme_font_size_override("font_size", 28)
		title.add_theme_color_override("font_color", Color(0.92, 0.94, 0.98, 1))
		header.add_child(title)

		var badge := Label.new()
		badge.name = "Badge"
		badge.add_theme_font_size_override("font_size", 22)
		if TankAgentManager.has_generated_script(key):
			badge.text = "已生成代码"
			badge.add_theme_color_override("font_color", Colors.success)
		else:
			badge.text = "使用默认脚本"
			badge.add_theme_color_override("font_color", Color(0.55, 0.58, 0.65, 1))
		header.add_child(badge)
		row.add_child(header)

		var editor := TextEdit.new()
		editor.name = "Editor"
		editor.custom_minimum_size = Vector2(0, 120)
		editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		editor.placeholder_text = "输入该坦克的策略描述，例如：优先拾取 buff，其次追击最近敌人，绝不误伤基地"
		editor.text = TankAgentManager.get_strategy(key)
		editor.add_theme_font_size_override("font_size", 22)
		row.add_child(editor)

		form.add_child(row)
		editors[key] = editor
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
	status_label.text = "策略已填写 %d / %d，已生成代码 %d / %d（游戏优先使用生成代码）" % [
		filled, total, generated, total
	]
	pass


func apply_editors_to_manager(clear_changed_scripts: bool) -> void:
	for key: String in TankAgentManager.AGENT_TANK_IDS:
		var editor: TextEdit = editors[key]
		var new_text := editor.text.strip_edges()
		var old_text := TankAgentManager.get_strategy(key)
		TankAgentManager.set_strategy(key, new_text)
		if clear_changed_scripts and old_text != new_text:
			TankAgentManager.delete_generated_script(key)
	pass


func on_button_hover() -> void:
	Audios.play_sfx(AudioConfig.UI_SELECT)
	pass


func on_save_pressed() -> void:
	if RateLimitUtils.limit_second_1() or generating:
		return
	Audios.play_sfx(AudioConfig.UI_CONFIRM)
	apply_editors_to_manager(true)
	TankAgentManager.save_strategies()
	build_form()
	refresh_status()
	Alert.alert("策略已保存", Colors.success)
	pass


func on_generate_pressed() -> void:
	if RateLimitUtils.limit_second_1() or generating:
		return
	Audios.play_sfx(AudioConfig.UI_CONFIRM)
	generating = true
	save_button.disabled = true
	generate_button.disabled = true
	back_button.disabled = true

	apply_editors_to_manager(false)
	TankAgentManager.save_strategies()
	status_label.text = "正在通过 AI 生成坦克代码…"
	Alert.alert("开始生成坦克代码", Colors.info)

	var result: Dictionary = await TankAgentManager.async_generate_all()
	generating = false
	save_button.disabled = false
	generate_button.disabled = false
	back_button.disabled = false

	build_form()
	refresh_status()

	var ok: int = result.get("ok", 0)
	var fail: int = result.get("fail", 0)
	if fail > 0:
		Alert.alert(StringUtils.format("生成完成：成功 {}，失败 {}", ok, fail), Colors.warning)
	elif ok > 0:
		Alert.alert(StringUtils.format("已生成 {} 个坦克脚本", ok), Colors.success)
	else:
		Alert.alert("没有可生成的策略文本", Colors.warning)
	pass


func on_back_pressed() -> void:
	if generating:
		return
	Audios.play_sfx(AudioConfig.UI_SELECT)
	await SceneHelper.async_change_scene_to_file(HOME_SCENE)
	pass
