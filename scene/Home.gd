extends Control

const INTRO_ANIMATION := "intro"
const TANK_FRAME_PATHS: Array[String] = [
	"res://image/characters/blue_tank_1.png",
	"res://image/characters/blue_tank_2.png",
	"res://image/characters/blue_tank_3.png",
	"res://image/characters/blue_tank_4.png",
	"res://image/characters/blue_tank_5.png",
	"res://image/characters/blue_tank_6.png",
]
const TANK_DISPLAY_SIZE := Vector2(240.0, 240.0)
const TANK_ANIMATION_FPS := 5.0

@onready var title_label: Label = $CenterContainer/VBox/HeaderRow/TitleLabel
@onready var tank_sprite: AnimatedSprite2D = $CenterContainer/VBox/HeaderRow/TankArea/TankSprite
@onready var menu_buttons: VBoxContainer = $CenterContainer/VBox/MenuButtons
@onready var continue_button: Button = $CenterContainer/VBox/MenuButtons/ContinueButton
@onready var ai_mode_button: Button = $CenterContainer/VBox/MenuButtons/AiModeButton
@onready var human_mode_button: Button = $CenterContainer/VBox/MenuButtons/HumanModeButton
@onready var exit_button: Button = $CenterContainer/VBox/MenuButtons/ExitButton


func _ready() -> void:
	menu_buttons.modulate.a = 0.0
	menu_buttons.visible = false
	continue_button.visible = GameSave.has_save()
	continue_button.pressed.connect(on_continue_pressed)
	ai_mode_button.pressed.connect(on_ai_mode_pressed)
	human_mode_button.pressed.connect(on_human_mode_pressed)
	exit_button.pressed.connect(on_exit_pressed)
	continue_button.mouse_entered.connect(on_button_hover)
	ai_mode_button.mouse_entered.connect(on_button_hover)
	human_mode_button.mouse_entered.connect(on_button_hover)
	exit_button.mouse_entered.connect(on_button_hover)
	setup_tank_animation()
	play_intro()
	Audio.play_voice(AudioConfig.BGM_OPENING_DEMO_PART2)
	pass


func setup_tank_animation() -> void:
	var frames := SpriteFrames.new()
	if not frames.has_animation(INTRO_ANIMATION):
		frames.add_animation(INTRO_ANIMATION)
	frames.set_animation_speed(INTRO_ANIMATION, TANK_ANIMATION_FPS)
	frames.set_animation_loop(INTRO_ANIMATION, true)

	for path in TANK_FRAME_PATHS:
		frames.add_frame(INTRO_ANIMATION, load(path))

	tank_sprite.sprite_frames = frames
	var texture_size := (frames.get_frame_texture(INTRO_ANIMATION, 0) as Texture2D).get_size()
	tank_sprite.scale = TANK_DISPLAY_SIZE / texture_size
	pass


func play_intro() -> void:
	await get_tree().process_frame
	title_label.modulate.a = 0.0
	title_label.scale = Vector2(0.6, 0.6)
	title_label.pivot_offset = title_label.size * 0.5

	var title_tween := create_tween().set_parallel(true)
	title_tween.tween_property(title_label, "modulate:a", 1.0, 0.8)
	title_tween.tween_property(title_label, "scale", Vector2.ONE, 0.8) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tank_sprite.play(INTRO_ANIMATION)
	await title_tween.finished
	show_menu_buttons()
	pass


func show_menu_buttons() -> void:
	menu_buttons.visible = true
	var tween := create_tween()
	tween.tween_property(menu_buttons, "modulate:a", 1.0, 0.4)
	pass


func on_button_hover() -> void:
	Audios.play_sfx(AudioConfig.UI_SELECT)
	pass


func on_continue_pressed() -> void:
	if RateLimitUtils.limit_second_1():
		return
	Audios.play_sfx(AudioConfig.UI_CONFIRM)
	GameManager.init()
	if !GameSave.load_save():
		continue_button.visible = false
		return
	Audio.stop_voice_fade()
	await SceneHelper.async_change_scene_to_file("res://scene/game/LevelReady.tscn")
	pass


func on_ai_mode_pressed() -> void:
	await start_game(BattleProgress.PlayMode.AI)
	pass


func on_human_mode_pressed() -> void:
	await start_game(BattleProgress.PlayMode.HUMAN)
	pass


func start_game(mode: BattleProgress.PlayMode) -> void:
	if RateLimitUtils.limit_second_1():
		return
	Audios.play_sfx(AudioConfig.UI_CONFIRM)
	GameManager.init()
	BattleProgress.play_mode = mode
	Audio.stop_voice_fade()
	await SceneHelper.async_change_scene_to_file("res://scene/game/LevelReady.tscn")
	pass


func on_exit_pressed() -> void:
	Audios.play_sfx(AudioConfig.UI_SELECT)
	await gdf.quit()
	pass
