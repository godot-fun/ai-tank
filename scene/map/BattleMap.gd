extends Node2D

const LEVEL_BRIEF_SCENE_PATH := "res://scene/ui/LevelBrief.tscn"
const HOME_SCENE_PATH := "res://scene/Home.tscn"
const STAGE_CLEAR_EFFECT_SCENE := "res://scene/effects/StageClearEffect.tscn"
const GAME_OVER_EFFECT_SCENE := "res://scene/effects/GameOverEffect.tscn"

@onready var battle_hud: BattleHud = $BattleHud

var enemy_spawner := EnemySpawner.new()
var battle_timer := 0.0


func _ready() -> void:
	BattleProgress.start_level()

	var time_limit := BattleProgress.get_time_limit()
	enemy_spawner.setup(EnemySpawner.get_enemy_count(), BattleProgress.get_time_limit())
	battle_timer = time_limit
	refresh_enemy_hud()
	battle_hud.update_timer(battle_timer)

	if Audio.musics.is_empty():
		Audio.set_audio_bus_volume_linear(Audio.AudioBusType.Music, 0.6)
		Audio.play_musics([AudioConfig.BGM_STAGE_1, AudioConfig.BGM_STAGE_2, AudioConfig.BGM_STAGE_3, AudioConfig.BGM_STAGE_4,
			AudioConfig.BGM_STAGE_5, AudioConfig.BGM_STAGE_6])
#		Audio.play_musics([AudioConfig.BGM_FC_STAGE_1, AudioConfig.BGM_FC_STAGE_2, AudioConfig.BGM_FC_STAGE_3, AudioConfig.BGM_FC_STAGE_4, AudioConfig.BGM_FC_STAGE_5])
	else:
		Audio.resume_musics()

	enemy_spawner.spawn_initial_wave()
	EventBus.events.enemy_tank_death.connect(on_enemy_tank_death)
	EventBus.events.eagle_death.connect(on_eagle_death)
	pass

func _exit_tree() -> void:
	EventBus.events.enemy_tank_death.disconnect(on_enemy_tank_death)
	EventBus.events.eagle_death.disconnect(on_eagle_death)
	pass

func _process(delta: float) -> void:
	if BattleProgress.level_ended:
		return

	battle_timer = maxf(battle_timer - delta, 0.0)
	battle_hud.update_timer(battle_timer)

	enemy_spawner.update(delta, battle_timer)

	if enemy_spawner.all_enemies_killed():
		end_level()
		return

	if battle_timer <= 0.0:
		end_level(GameOverEffect.FailReason.TIME_UP)
	pass


func on_enemy_tank_death(tank: Tank) -> void:
	enemy_spawner.on_enemy_tank_death()
	refresh_enemy_hud()
	pass


func on_eagle_death() -> void:
	gdf.callable_deferred(end_level.bind(GameOverEffect.FailReason.EAGLE_DESTROYED))
	pass


func refresh_enemy_hud() -> void:
	battle_hud.update_enemies_remaining(enemy_spawner.get_remaining_count())
	pass


func end_level(fail_reason = null) -> void:
	if BattleProgress.level_ended:
		return

	set_process(false)
	set_physics_process(false)
	process_mode = Node.ProcessMode.PROCESS_MODE_DISABLED

	if fail_reason == null:
		BattleProgress.end_level()
		Audios.play_sfx(AudioConfig.STAGE_CLEAR)
		Audio.pause_musics()
		var clear_effect: StageClearEffect = load(STAGE_CLEAR_EFFECT_SCENE).instantiate()
		add_child(clear_effect)
		await ThreadUtils.async_sleep(4000)
		await SceneHelper.async_change_scene_to_file(LEVEL_BRIEF_SCENE_PATH)
	else:
		BattleProgress.fail_level()
		Audios.play_sfx(AudioConfig.GAME_OVER)
		Audio.stop_music()
		var game_over_effect: GameOverEffect = load(GAME_OVER_EFFECT_SCENE).instantiate()
		game_over_effect.fail_reason = fail_reason
		add_child(game_over_effect)
		await ThreadUtils.async_sleep(4000)
		await SceneHelper.async_change_scene_to_file(HOME_SCENE_PATH)
	pass
