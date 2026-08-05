extends Control

const HOME_SCENE := "res://scene/Home.tscn"
const TANK_ICON_SIZE := 72.0
const SPINNER_SIZE := Vector2(72, 72)

@onready var form: VBoxContainer = $Margin/VBox/Scroll/Form
@onready var status_label: Label = $Margin/VBox/StatusLabel
@onready var back_button: Button = $BackButton
@onready var loading_overlay: ColorRect = $LoadingOverlay
@onready var loading_spinner: Control = $LoadingOverlay/Center/VBox/Spinner
@onready var loading_label: Label = $LoadingOverlay/Center/VBox/LoadingLabel

var editors: Dictionary = {}
var generate_buttons: Dictionary = {}
var generating := false
var spinner_tween: Tween


func _ready() -> void:
	back_button.pressed.connect(on_back_pressed)
	back_button.mouse_entered.connect(on_button_hover)
	loading_spinner.draw.connect(on_spinner_draw)
	loading_spinner.custom_minimum_size = SPINNER_SIZE
	loading_spinner.pivot_offset = SPINNER_SIZE * 0.5
	loading_spinner.queue_redraw()
	loading_overlay.visible = false
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

		var name_label := Label.new()
		name_label.name = "TankName"
		name_label.text = key
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 26)
		name_label.add_theme_color_override("font_color", Color(0.92, 0.94, 0.98, 1))
		header.add_child(name_label)

		var generate_button := Button.new()
		generate_button.name = "GenerateButton"
		generate_button.text = "生成策略"
		generate_button.custom_minimum_size = Vector2(160, 56)
		generate_button.add_theme_font_size_override("font_size", 24)
		style_generate_button(generate_button)
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


func set_busy(busy: bool, key: String = "") -> void:
	generating = busy
	back_button.disabled = busy
	for button_key: String in generate_buttons:
		var button: Button = generate_buttons[button_key]
		button.disabled = busy
	if busy:
		show_loading(key)
	else:
		hide_loading()
	pass


func show_loading(key: String) -> void:
	loading_label.text = StringUtils.format("正在生成 {} 的策略代码…", key)
	loading_overlay.visible = true
	start_spinner()
	pass


func hide_loading() -> void:
	loading_overlay.visible = false
	stop_spinner()
	pass


func start_spinner() -> void:
	stop_spinner()
	loading_spinner.rotation = 0.0
	spinner_tween = create_tween().set_loops()
	spinner_tween.tween_property(loading_spinner, "rotation", TAU, 0.9).from(0.0)
	pass


func stop_spinner() -> void:
	if spinner_tween != null and spinner_tween.is_valid():
		spinner_tween.kill()
	spinner_tween = null
	loading_spinner.rotation = 0.0
	pass


func on_spinner_draw() -> void:
	var center := SPINNER_SIZE * 0.5
	var radius := mini(center.x, center.y) - 6.0
	loading_spinner.draw_arc(center, radius, 0.0, TAU * 0.72, 48, Color(0.45, 0.78, 1.0, 1.0), 8.0, true)
	pass


func style_generate_button(button: Button) -> void:
	button.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.9, 0.95, 1.0, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.75, 0.8, 0.85, 0.7))
	button.add_theme_stylebox_override("normal", make_generate_style(Colors.info))
	button.add_theme_stylebox_override("hover", make_generate_style(Colors.info.lightened(0.12)))
	button.add_theme_stylebox_override("pressed", make_generate_style(Colors.info.darkened(0.12)))
	button.add_theme_stylebox_override("disabled", make_generate_style(Color(0.25, 0.32, 0.4, 1.0)))
	pass


func make_generate_style(bg: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_top = 10
	style.content_margin_right = 16
	style.content_margin_bottom = 10
	return style


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

	set_busy(true, key)
	status_label.text = StringUtils.format("正在生成 {} 的策略代码…", key)

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
