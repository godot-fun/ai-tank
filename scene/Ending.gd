extends Control

## 通关结局：播放通关视频后返回主菜单。
const ENDING_VIDEO_PATH := "res://assets/video/tank-ending.ogv"
const HOME_SCENE_PATH := "res://scene/Home.tscn"

@onready var ending_video: VideoStreamPlayer = $EndingVideo
@onready var enter_prompt: Label = $EnterPrompt


func _ready() -> void:
	set_process_input(false)
	Audio.play_music_fade(AudioConfig.BGM_ENDING)
	play_ending_video()
	pass


func play_ending_video() -> void:
	var stream := await ResourceHelper.async_load(ENDING_VIDEO_PATH) as VideoStream
	if stream != null:
		ending_video.stream = stream
		ending_video.visible = true
		ending_video.play()
		await ending_video.finished

	await show_enter_prompt()
	pass


func show_enter_prompt() -> void:
	enter_prompt.modulate.a = 0.0
	enter_prompt.visible = true

	var fade_tween := create_tween()
	fade_tween.tween_property(enter_prompt, "modulate:a", 1.0, 0.5)
	await fade_tween.finished

	set_process_input(true)

	var pulse_tween := create_tween().set_loops()
	pulse_tween.tween_property(enter_prompt, "modulate:a", 0.4, 0.8)
	pulse_tween.tween_property(enter_prompt, "modulate:a", 1.0, 0.8)
	pass


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		set_process_input(false)
		on_enter_pressed()
	pass


func on_enter_pressed() -> void:
	Audios.play_sfx(AudioConfig.UI_CONFIRM)
	Audio.stop_music_fade()
	await SceneHelper.async_change_scene_to_file(HOME_SCENE_PATH)
	pass
