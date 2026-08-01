extends Node2D

const LEVEL_COUNT := 35
const INTERVAL_SEC := 2.0

var _level_label: Label
var _pause_button: Button

var _level_index := 0
var _wait_timer := 0.0
var _paused := false


func _ready() -> void:
	_setup_hud()
	set_process(true)


func _process(delta: float) -> void:
	if _paused or _level_index >= LEVEL_COUNT:
		return

	_wait_timer -= delta
	if _wait_timer > 0.0:
		return

	_update_level_label(_level_index)
	LevelConfig.load_level(_level_index)
	_level_index += 1
	_wait_timer = INTERVAL_SEC if _level_index < LEVEL_COUNT else 0.0


func _setup_hud() -> void:
	var hud_layer := CanvasLayer.new()
	hud_layer.name = "HudLayer"
	hud_layer.layer = 10
	add_child(hud_layer)

	_level_label = Label.new()
	_level_label.name = "LevelLabel"
	_level_label.add_theme_font_size_override("font_size", 36)
	_level_label.add_theme_color_override("font_color", Color(0.92, 0.94, 0.98))
	_level_label.position = Vector2(32, 24)
	hud_layer.add_child(_level_label)

	_pause_button = Button.new()
	_pause_button.name = "PauseButton"
	_pause_button.text = "暂停"
	_pause_button.custom_minimum_size = Vector2(120, 48)
	_pause_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_pause_button.offset_left = -152
	_pause_button.offset_top = 24
	_pause_button.offset_right = -32
	_pause_button.offset_bottom = 72
	_pause_button.pressed.connect(_on_pause_pressed)
	hud_layer.add_child(_pause_button)


func _on_pause_pressed() -> void:
	_paused = not _paused
	_pause_button.text = "继续" if _paused else "暂停"


func _update_level_label(level_index: int) -> void:
	_level_label.text = "第 %d 关" % (level_index + 1)
