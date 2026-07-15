extends Node2D

const LEVEL_BRIEF_SCENE_PATH := "res://scene/ui/LevelBrief.tscn"
const STAGE_CLEAR_EFFECT_SCENE := "res://scene/effects/StageClearEffect.tscn"

@onready var battle_hud: BattleHud = $BattleHud

var enemy_spawner := EnemySpawner.new()
var battle_timer := 0.0


func _ready() -> void:
	BattleProgress.level_ended = false
	LevelConfig.load_level(BattleProgress.level)
	Eagle.create_base()
	TankHelper.create_tank(TankConfig.my_tank, Eagle.my_tank_start_grid_pos)
	TankHelper.create_tank(TankConfig.partner_tank, Eagle.partner_start_grid_pos)

	enemy_spawner.setup(BattleProgress.get_enemy_count())
	battle_timer = BattleProgress.get_time_limit()
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
	pass

func _exit_tree() -> void:
	EventBus.events.enemy_tank_death.disconnect(on_enemy_tank_death)
	pass

func _process(delta: float) -> void:
	if BattleProgress.level_ended:
		return

	battle_timer = maxf(battle_timer - delta, 0.0)
	battle_hud.update_timer(battle_timer)

	enemy_spawner.update(delta)

	if enemy_spawner.all_enemies_killed():
		end_level(true)
		return

	if battle_timer <= 0.0:
		end_level(false)
	pass


func on_enemy_tank_death(tank: Tank) -> void:
	enemy_spawner.on_enemy_tank_death()
	refresh_enemy_hud()
	pass


func refresh_enemy_hud() -> void:
	battle_hud.update_enemies_remaining(enemy_spawner.get_remaining_count())
	pass


func end_level(cleared: bool) -> void:
	if BattleProgress.level_ended:
		return

	BattleProgress.level_ended = true
	set_process(false)
	set_physics_process(false)
	process_mode = Node.ProcessMode.PROCESS_MODE_DISABLED
	
	Audios.play_sfx(AudioConfig.STAGE_CLEAR)
	Audio.pause_musics()
	var effect: StageClearEffect = load(STAGE_CLEAR_EFFECT_SCENE).instantiate()
	add_child(effect)
	await ThreadUtils.async_sleep(4000)

	BattleProgress.next_level()
	await SceneHelper.async_change_scene_to_file(LEVEL_BRIEF_SCENE_PATH)
	pass
