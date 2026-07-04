extends Control

const OPENING_VIDEO_PATH := "res://assets/video/tank-opening-1.ogv"
const HOME_SCENE_PATH := "res://scene/Home.tscn"

@onready var opening_video: VideoStreamPlayer = $OpeningVideo
@onready var enter_prompt: Label = $EnterPrompt

var _waiting_for_enter := false


func _ready() -> void:
	Audio.play_music(BgmConfig.BGM_OPENING_DEMO_PART1)
	play_opening_video()
	pass


func play_opening_video() -> void:
	var stream := await ResourceHelper.async_load(OPENING_VIDEO_PATH) as VideoStream
	if stream != null:
		opening_video.stream = stream
		opening_video.visible = true
		opening_video.play()
		await opening_video.finished
		opening_video.stop()

	await show_enter_prompt()
	_waiting_for_enter = true
	pass


func show_enter_prompt() -> void:
	enter_prompt.modulate.a = 0.0
	enter_prompt.visible = true

	var fade_tween := create_tween()
	fade_tween.tween_property(enter_prompt, "modulate:a", 1.0, 0.5)
	await fade_tween.finished

	var pulse_tween := create_tween().set_loops()
	pulse_tween.tween_property(enter_prompt, "modulate:a", 0.4, 0.8)
	pulse_tween.tween_property(enter_prompt, "modulate:a", 1.0, 0.8)
	pass


func _input(event: InputEvent) -> void:
	if not _waiting_for_enter:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		on_enter_pressed()
	pass


func on_enter_pressed() -> void:
	_waiting_for_enter = false
	Audios.play("res://audio/sfx/ui-confirm/01.wav")
	await SceneHelper.async_change_scene_to_file(HOME_SCENE_PATH)
	pass
