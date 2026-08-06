extends Control

@onready var title_label: Label = $CenterContainer/VBox/TitleLabel
@onready var menu_buttons: VBoxContainer = $CenterContainer/VBox/MenuButtons
@onready var continue_button: Button = $CenterContainer/VBox/MenuButtons/ContinueButton
@onready var ai_mode_button: Button = $CenterContainer/VBox/MenuButtons/AiModeButton
@onready var human_mode_button: Button = $CenterContainer/VBox/MenuButtons/HumanModeButton
@onready var tank_agent_button: Button = $CenterContainer/VBox/MenuButtons/TankAgentButton
@onready var exit_button: Button = $CenterContainer/VBox/MenuButtons/ExitButton


func _ready() -> void:
	menu_buttons.modulate.a = 0.0
	menu_buttons.visible = false
	continue_button.visible = GameSave.has_save()
	continue_button.pressed.connect(on_continue_pressed)
	ai_mode_button.pressed.connect(on_ai_mode_pressed)
	human_mode_button.pressed.connect(on_human_mode_pressed)
	tank_agent_button.pressed.connect(on_tank_agent_pressed)
	exit_button.pressed.connect(on_exit_pressed)
	continue_button.mouse_entered.connect(on_button_hover)
	ai_mode_button.mouse_entered.connect(on_button_hover)
	human_mode_button.mouse_entered.connect(on_button_hover)
	tank_agent_button.mouse_entered.connect(on_button_hover)
	exit_button.mouse_entered.connect(on_button_hover)
	play_intro()
	Audio.play_voice(AudioConfig.BGM_OPENING_DEMO_PART2)
	init_home_battle()
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


func on_tank_agent_pressed() -> void:
	if RateLimitUtils.limit_second_1():
		return
	Audios.play_sfx(AudioConfig.UI_CONFIRM)
	Audio.stop_voice_fade()
	await SceneHelper.async_change_scene_to_file("res://scene/ui/TankAgent.tscn")
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




# ---------------------------------------------------------------------------------------------------------------------
const ENEMY_WAVE_INTERVAL := 5.0
const JEEP_WAVE_INTERVAL := 7.0
const BOSS_SPAWN_INTERVAL := 30.0

## 在 Home 场景初始化我方 6 辆坦克，并按节奏刷敌坦克 / jeep / boss
func init_home_battle() -> void:
	$Background.visible = false
	$CenterContainer.z_index = 100
	GameManager.init()
	BuffManager.start_level()
	LevelConfig.load_level(0)
	Eagle.create_base()

	TankHelper.create_tank(TankConfig.my_tank, Eagle.player_tank_start_grid_pos)
	var partners: Array[TankConfig.TankData] = [
		TankConfig.tank_2, TankConfig.tank_3, TankConfig.tank_4, TankConfig.tank_5, TankConfig.tank_6,
	]
	for data in partners:
		TankHelper.create_tank(data, Eagle.partner_tank_start_grid_pos)

	spawn_wave(TankConfig.enemy_easy)
	loop_spawn(spawn_wave.bind(TankConfig.enemy_easy), ENEMY_WAVE_INTERVAL)
	loop_spawn(spawn_wave.bind(TankConfig.enemy_jeep), JEEP_WAVE_INTERVAL)
	loop_spawn(spawn_boss, BOSS_SPAWN_INTERVAL)
	pass


func loop_spawn(callback: Callable, interval: float) -> void:
	var tween := create_tween().set_loops()
	tween.tween_interval(interval)
	tween.tween_callback(callback)
	pass



func spawn_wave(tank_data: TankConfig.TankData) -> void:
	for grid in EnemySpawner.spawn_grids:
		TankHelper.create_tank(tank_data, grid)
	pass


func spawn_boss() -> void:
	var tank := TankHelper.create_tank(TankConfig.boss_enemy_easy, EnemySpawner.spawn_grids[1])
	if tank != null:
		tank.scale_tank_deferred()
	pass