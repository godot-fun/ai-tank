extends Tank
class_name MyTank


func start() -> void:
	apply_data(TankConfig.my_tank)
	pass


func update(_delta: float) -> void:
	if Input.is_action_pressed("ui_accept"):
		fire()

	if moving:
		return

	var direction := read_direction()
	if direction != Vector2i.ZERO:
		move(direction)
		play_move_sound()
	else:
		stop_move_sound()
	pass


func read_direction() -> Vector2i:
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		return Vector2i.UP
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		return Vector2i.DOWN
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		return Vector2i.LEFT
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		return Vector2i.RIGHT
	return Vector2i.ZERO

########################################################################################################################
# move sound
var move_sound_fade_tween: Tween = null

func play_move_sound() -> void:
	var audio: AudioStreamPlayer = Audio.audio_map[Audio.AudioBusType.Ambience]
	if move_sound_fade_tween != null and move_sound_fade_tween.is_valid():
		move_sound_fade_tween.kill()
		move_sound_fade_tween = null
		audio.volume_linear = 1.0
	if Audio.is_playing_ambience() and audio.stream != null:
		var remaining: float = audio.stream.get_length() - audio.get_playback_position()
		if remaining > 1.0:
			return
		audio.volume_linear = 1.0
		audio.seek(1.0)
		return
	Audio.play_ambience(TankConfig.AUDIO_TANK_MOVE)
	pass

func stop_move_sound() -> void:
	if !Audio.is_playing_ambience():
		return
	if move_sound_fade_tween != null and move_sound_fade_tween.is_valid():
		return
	var audio: AudioStreamPlayer = Audio.audio_map[Audio.AudioBusType.Ambience]
	move_sound_fade_tween = audio.create_tween()
	move_sound_fade_tween.tween_property(audio, "volume_linear", 0.0, 0.5)
	move_sound_fade_tween.tween_callback(func() -> void:
		move_sound_fade_tween = null
		Audio.stop_ambience()
		audio.volume_linear = 1.0
	)
	pass