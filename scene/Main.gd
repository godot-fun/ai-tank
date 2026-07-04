extends Control

const OPENING_VIDEO_PATH := "res://assets/video/tank-opening-1.ogv"
const HOME_SCENE_PATH := "res://scene/Home.tscn"

@onready var opening_video: VideoStreamPlayer = $OpeningVideo


func _ready() -> void:
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

	await SceneHelper.async_change_scene_to_file(HOME_SCENE_PATH)
	pass
