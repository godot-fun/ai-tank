extends Control

const BATTLE_SCENE_PATH := "res://scene/map/BattleMap.tscn"

@onready var level_label: Label = $CenterContainer/VBox/LevelLabel
@onready var score_label: Label = $CenterContainer/VBox/ScoreLabel
@onready var tap_prompt: Label = $TapPrompt


func _ready() -> void:
	set_process_input(false)
	level_label.text = "第 %d 关" % (BattleProgress.level + 1)
	score_label.text = "分数 %d" % BattleProgress.score
	show_tap_prompt()
	Audios.play_sfx(AudioConfig.STAGE_START)
	pass


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
