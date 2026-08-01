extends Node2D

const LEVEL_READY_SCENE_PATH := "res://scene/game/LevelReady.tscn"
const ENDING_SCENE_PATH := "res://scene/Ending.tscn"
const HOME_SCENE_PATH := "res://scene/Home.tscn"
const STAGE_CLEAR_EFFECT_SCENE := "res://scene/effects/StageClearEffect.tscn"
const GAME_OVER_EFFECT_SCENE := "res://scene/effects/GameOverEffect.tscn"

@onready var battle_hud: BattleHud = $BattleHud

var enemy_spawner := EnemySpawner.new()
var battle_timer := 0.0


func _ready() -> void:
	BattleProgress.start_level()

	var time_limit := BattleProgress.get_time_limit()
	enemy_spawner.setup(BattleProgress.get_time_limit(), BattleProgress.level)
	battle_timer = time_limit
	battle_hud.update_timer(battle_timer)

	Audio.play_music_fade(BattleProgress.get_current_level_music())
	
	enemy_spawner.spawn_initial_wave()
	refresh_wave_hud()
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

	BattleProgress.update(delta)
	battle_timer = maxf(battle_timer - delta, 0.0)
	battle_hud.update_timer(battle_timer)

	enemy_spawner.update(delta, battle_timer)
	refresh_wave_hud()

	if enemy_spawner.all_enemies_killed():
		end_level()
		return

	if battle_timer <= 0.0:
		end_level(GameOverEffect.FailReason.TIME_UP)
	pass


func on_enemy_tank_death(tank: Tank) -> void:
	enemy_spawner.on_enemy_tank_death()
	pass


func on_eagle_death() -> void:
	if BattleProgress.level_ended:
		return
	gdf.callable_deferred(end_level.bind(GameOverEffect.FailReason.EAGLE_DESTROYED))
	pass


func refresh_wave_hud() -> void:
	battle_hud.update_waves_remaining(enemy_spawner.get_remaining_wave_count())
	pass


func end_level(fail_reason = null) -> void:
	if BattleProgress.level_ended:
		return
	# 让战场上的所有物体都停止
#	set_process(false)
#	set_physics_process(false)
#	process_mode = Node.ProcessMode.PROCESS_MODE_DISABLED
	
	Audio.stop_music()
	
	if fail_reason == null:
		BattleProgress.end_level()
		GameSave.save()
		Audios.play_sfx(AudioConfig.STAGE_CLEAR)
		var clear_effect: StageClearEffect = load(STAGE_CLEAR_EFFECT_SCENE).instantiate()
		clear_effect.name = "StageClearEffect"
		add_child(clear_effect)
		await ThreadUtils.async_sleep(4000)
		if BattleProgress.is_game_cleared():
			await SceneHelper.async_change_scene_to_file(ENDING_SCENE_PATH)
		else:
			await SceneHelper.async_change_scene_to_file(LEVEL_READY_SCENE_PATH)
	else:
		BattleProgress.fail_level()
		Audios.play_sfx(AudioConfig.GAME_OVER)
		var game_over_effect: GameOverEffect = load(GAME_OVER_EFFECT_SCENE).instantiate()
		game_over_effect.name = "GameOverEffect"
		game_over_effect.fail_reason = fail_reason
		add_child(game_over_effect)
	pass
