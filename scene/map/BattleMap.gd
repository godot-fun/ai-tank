extends Node2D

const ENEMY_SPAWN_INTERVAL := 5.0
const LEVEL_BRIEF_SCENE_PATH := "res://scene/ui/LevelBrief.tscn"
const STAGE_CLEAR_EFFECT_SCENE := "res://scene/effects/StageClearEffect.tscn"

@warning_ignore("integer_division")
static var enemy_spawn_grids: Array[Vector2i] = [
	Vector2i(0, 0),
	Vector2i((TileConfig.MAP_GRID_WIDTH - TankConfig.enemy_easy.grid_size.x) / 2, 0),
	Vector2i(TileConfig.MAP_GRID_WIDTH - TankConfig.enemy_easy.grid_size.x, 0),
]

@onready var battle_hud: BattleHud = $BattleHud

var total_enemies := 0
var enemies_spawned := 0
var enemies_killed := 0
var spawn_timer := 0.0
var battle_timer := 0.0
var level_ended := false


func _ready() -> void:
	LevelConfig.load_level(BattleProgress.level)
	Eagle.create_base()
	TankHelper.create_tank(TankConfig.my_tank, Eagle.my_tank_start_grid_pos)
	TankHelper.create_tank(TankConfig.partner_tank, Eagle.partner_start_grid_pos)

	total_enemies = BattleProgress.get_enemy_count()
	battle_timer = BattleProgress.get_time_limit()
	refresh_enemy_hud()
	battle_hud.update_timer(battle_timer)

	if Audio.musics.is_empty():
		Audio.play_musics([BgmConfig.BGM_STAGE_1, BgmConfig.BGM_STAGE_2, BgmConfig.BGM_STAGE_3, BgmConfig.BGM_STAGE_4,
			BgmConfig.BGM_STAGE_5, BgmConfig.BGM_STAGE_6])
#		Audio.play_musics([BgmConfig.BGM_FC_STAGE_1, BgmConfig.BGM_FC_STAGE_2, BgmConfig.BGM_FC_STAGE_3, BgmConfig.BGM_FC_STAGE_4, BgmConfig.BGM_FC_STAGE_5])
	else:
		Audio.resume_musics()

	spawn_enemy_wave()
	pass


func _process(delta: float) -> void:
	if level_ended:
		return

	battle_timer = maxf(battle_timer - delta, 0.0)
	battle_hud.update_timer(battle_timer)

	spawn_timer += delta
	if spawn_timer >= ENEMY_SPAWN_INTERVAL:
		spawn_timer = 0.0
		spawn_enemy_wave()

	if enemies_killed >= total_enemies:
		end_level(true)
		return

	if battle_timer <= 0.0:
		end_level(false)
	pass


func spawn_enemy_wave() -> void:
	if enemies_spawned >= total_enemies:
		return

	for grid in enemy_spawn_grids:
		if enemies_spawned >= total_enemies:
			break
		if try_spawn_enemy_at(grid):
			enemies_spawned += 1
	pass


func try_spawn_enemy_at(grid: Vector2i) -> bool:
	var grid_size := TankConfig.enemy_easy.grid_size
	if TankHelper.is_move_blocked(grid, grid_size):
		return false

	TankHelper.create_tank(TankConfig.enemy_easy, grid)
	return true


func on_enemy_killed() -> void:
	enemies_killed += 1
	refresh_enemy_hud()
	if not level_ended and enemies_killed >= total_enemies:
		end_level(true)
	pass


func refresh_enemy_hud() -> void:
	battle_hud.update_enemies_remaining(total_enemies - enemies_killed)
	pass


func end_level(cleared: bool) -> void:
	if level_ended:
		return

	level_ended = true
	set_process(false)
	Audio.pause_musics()

	Audios.play(BgmConfig.BGM_STAGE_CLEAR)
	var effect: StageClearEffect = load(STAGE_CLEAR_EFFECT_SCENE).instantiate()
	add_child(effect)
	await ThreadUtils.async_sleep(6000)

	BattleProgress.next_level()
	await SceneHelper.async_change_scene_to_file(LEVEL_BRIEF_SCENE_PATH)
	pass

