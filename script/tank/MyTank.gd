extends Tank
class_name MyTank

const SHAKE_SHADER := "res://shader/tank_move_shake.gdshader"
const RELOAD_INDICATOR_MARGIN := 8.0
const HOLD_MOVE_DELAY := 0.12

var shake_material: ShaderMaterial
var reload_indicator: ReloadIndicator
## < 0: already facing, move immediately. >= 0: hold time after a turn.
var direction_hold_time := -1.0


func start() -> void:
	setup_shake_material()
	setup_reload_indicator()
	pass


func _process(_delta: float) -> void:
	update_shake_shader()
	update_reload_indicator()
	pass


func setup_shake_material() -> void:
	shake_material = ShaderMaterial.new()
	shake_material.shader = load(SHAKE_SHADER)
	sprite.material = shake_material
	update_shake_shader()
	pass


func update_shake_shader() -> void:
	if shake_material == null:
		return
	shake_material.set_shader_parameter("move_amount", 1.0 if moving else 0.0)
	shake_material.set_shader_parameter("world_scale", absf(sprite.scale.x))
	pass


func physics_update(delta: float) -> void:
	if Input.is_action_pressed("ui_accept"):
		fire()

	if moving:
		return

	var direction := read_direction()
	if direction == Vector2i.ZERO:
		direction_hold_time = -1.0
		stop_move_sound()
		return

	if direction != facing:
		update_facing(direction)
		direction_hold_time = 0.0
		stop_move_sound()
		return

	if direction_hold_time >= 0.0:
		direction_hold_time += delta
		if direction_hold_time < HOLD_MOVE_DELAY:
			stop_move_sound()
			return
		direction_hold_time = -1.0

	move(direction)
	play_move_sound()
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
	Audio.play_ambience(AudioConfig.TANK_MOVE)
	pass

func stop_move_sound() -> void:
	if !Audio.is_playing_ambience():
		return
	if move_sound_fade_tween != null and move_sound_fade_tween.is_valid():
		return
	var audio: AudioStreamPlayer = Audio.audio_map[Audio.AudioBusType.Ambience]
	move_sound_fade_tween = create_tween()
	move_sound_fade_tween.tween_property(audio, "volume_linear", 0.0, 0.5)
	move_sound_fade_tween.tween_callback(func() -> void:
		move_sound_fade_tween = null
		Audio.stop_ambience()
		audio.volume_linear = 1.0
	)
	pass


########################################################################################################################
# fire cool down
func setup_reload_indicator() -> void:
	reload_indicator = ReloadIndicator.new()
	reload_indicator.name = "ReloadIndicator"
	add_child(reload_indicator)
	pass


func update_reload_indicator() -> void:
	if reload_indicator == null:
		return

	var tank_half_height := float(grid_size.y * TileConfig.TILE_SIZE) * 0.5
	var indicator_position := global_position + Vector2(
		0.0,
		-tank_half_height - ReloadIndicator.RADIUS - RELOAD_INDICATOR_MARGIN,
	)
	reload_indicator.update_reload(
		indicator_position,
		fire_cooldown,
		bullet_fire_interval,
	)
	pass
	
########################################################################################################################