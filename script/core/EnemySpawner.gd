class_name EnemySpawner

@warning_ignore("integer_division")
static var spawn_grids: Array[Vector2i] = [
	Vector2i(0, 0),
	Vector2i((TileConfig.MAP_GRID_WIDTH - TankConfig.enemy_easy.grid_size.x) / 2, 0),
	Vector2i(TileConfig.MAP_GRID_WIDTH - TankConfig.enemy_easy.grid_size.x, 0),
]

const ENEMY_WAVE: Array[int] = [2, 3, 3, 5, 6, 8, 9, 10, 11, 12, 
								13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 
								23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 
								33, 33, 33, 35, 35]

const ELITE_ENEMY_WAVE: Array[int] = [1, 1, 2, 1, 1, 1, 1, 1, 2, 2
									, 1, 1, 1, 3, 3, 1, 1, 1, 3, 3
									, 2, 2, 2, 4, 4, 2, 2, 2, 4, 4
									, 3, 3, 3, 5, 5]

const MINI_BOSS_ENEMY_SPAWN_LEVEL: Array[int] = [3, 8, 9, 13, 18, 19, 23, 28, 29, 33, 34]
const BOSS_ENEMY_SPAWN_LEVEL: Array[int] = [4, 9, 14, 19, 24, 29, 34]

var level: int = 0
var enemies_spawned_wave := 0
var elite_enemies_spawned_wave := 0
var enemies_killed := 0
var spawn_timer := 0.0
var spawn_interval := 0.0
var remaining_time := 0.0
var spawn_finish_early_seconds := 0.0
var spawn_mini_boss_enemy_seconds := 0.0
var spawn_boss_enemy_seconds := 0.0


func setup(time_limit: float, _level: int) -> void:
	level = _level
	enemies_spawned_wave = 0
	elite_enemies_spawned_wave = 0
	enemies_killed = 0
	spawn_timer = 0.0
	remaining_time = time_limit
	spawn_finish_early_seconds = time_limit * 0.6
	
	if MINI_BOSS_ENEMY_SPAWN_LEVEL.find(level) >= 0:
		spawn_mini_boss_enemy_seconds = time_limit * 0.7
		
	if BOSS_ENEMY_SPAWN_LEVEL.find(level) >= 0:
		spawn_boss_enemy_seconds = time_limit * 0.7
	
	calculate_spawn_interval(time_limit)


func spawn_initial_wave() -> void:
	spawn_enemy_wave()


func update(delta: float, time_remaining: float) -> void:
	remaining_time = time_remaining

	if time_remaining <= spawn_finish_early_seconds:
		spawn_enemy_wave()
		return

	if time_remaining <= spawn_mini_boss_enemy_seconds:
		spawn_mini_boss_enemy()
		return
	
	if time_remaining <= spawn_boss_enemy_seconds:
		spawn_boss_enemy()
		return

	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		spawn_enemy_wave()


# ----------------------------------------------------------------------------------------------------------------------
func spawn_enemy_wave() -> void:
	if get_waves_spawned() >= get_total_enemy_wave_count():
		return

	var is_elite_wave := should_spawn_elite_wave()
	var tank_data: TankConfig.TankData = TankConfig.enemy_easy
	var buff_size := enemies_spawned_wave / 30
	if is_elite_wave:
		tank_data = TankConfig.elite_enemy_easy
		buff_size = elite_enemies_spawned_wave / 10
		elite_enemies_spawned_wave += 1
	else:
		enemies_spawned_wave += 1

	for i in range(spawn_grids.size()):
		var buffs := enemy_random_buff(buff_size)
		var tank := TankHelper.create_tank_with_buffs(tank_data, spawn_grids[i], buffs)
		if tank == null:
			continue
		BuffManager.update_tank_appearance(tank, buffs)
	pass

func spawn_mini_boss_enemy() -> void:
	var tank_data: TankConfig.TankData = TankConfig.mini_boss_enemy_easy
	var buff_size: int= BattleProgress.level / 4
	var buffs := enemy_random_buff(buff_size)
	var tank := TankHelper.create_tank_with_buffs(tank_data, spawn_grids[1], buffs)
	if tank == null:
		return
	var tank_resources := ["res://image/characters/gray_tank_7.png", "res://image/characters/gray_tank_8.png", "res://image/characters/gray_tank_9.png"]
	var tank_resource: String = RandomUtils.random_ele(tank_resources)
	tank.tank_resource = tank_resource
	tank.scale_tank()
	tank.hp = tank.hp + BattleProgress.level * 2
	spawn_mini_boss_enemy_seconds = 0
	Audio.play_music_fade(AudioConfig.BGM_FC_BOSS_BATTLE)
	pass
	
func spawn_boss_enemy() -> void:
	var tank_data: TankConfig.TankData = TankConfig.boss_enemy_easy
	var buff_size: int= BattleProgress.level / 3
	var buffs := enemy_random_buff(buff_size)
	var tank := TankHelper.create_tank_with_buffs(tank_data, spawn_grids[1], buffs)
	if tank == null:
		return
	var tank_resources := ["res://image/characters/red_tank_7.png", "res://image/characters/red_tank_8.png"]
	var tank_resource: String = RandomUtils.random_ele(tank_resources)
	tank.tank_resource = tank_resource
	tank.scale_tank()
	tank.hp = tank.hp + BattleProgress.level * 3
	spawn_boss_enemy_seconds = 0
	Audio.play_music_fade(AudioConfig.BGM_BOSS_BATTLE)
	pass
# ----------------------------------------------------------------------------------------------------------------------
func get_waves_spawned() -> int:
	return enemies_spawned_wave + elite_enemies_spawned_wave


func get_enemy_wave_count() -> int:
	return ENEMY_WAVE[min(level, ENEMY_WAVE.size() - 1)]


func get_elite_enemy_wave_count() -> int:
	return ELITE_ENEMY_WAVE[min(level, ELITE_ENEMY_WAVE.size() - 1)]


func get_total_enemy_wave_count() -> int:
	return get_enemy_wave_count() + get_elite_enemy_wave_count()


func get_total_enemies() -> int:
	var total := get_total_enemy_wave_count() * spawn_grids.size()
	if MINI_BOSS_ENEMY_SPAWN_LEVEL.find(level) >= 0:
		total += 1
	if BOSS_ENEMY_SPAWN_LEVEL.find(level) >= 0:
		total += 1
	return total


func should_spawn_elite_wave() -> bool:
	var elite_count := get_elite_enemy_wave_count()
	if elite_enemies_spawned_wave >= elite_count:
		return false
	if enemies_spawned_wave >= get_enemy_wave_count():
		return true
	var elite_spawn_interval := maxi(1, get_enemy_wave_count() / maxi(1, elite_count))
	return enemies_spawned_wave > 0 and enemies_spawned_wave % elite_spawn_interval == 0


func calculate_spawn_interval(time_limit: float) -> void:
	var spawn_window := maxf(time_limit - spawn_finish_early_seconds, 0.0)
	var total_waves := get_total_enemy_wave_count()
	if total_waves <= 1:
		spawn_interval = spawn_window
	else:
		spawn_interval = spawn_window / float(total_waves - 1)


func on_enemy_tank_death() -> void:
	enemies_killed += 1


func get_remaining_count() -> int:
	return get_total_enemies() - enemies_killed


func all_spawns_complete() -> bool:
	if get_waves_spawned() < get_total_enemy_wave_count():
		return false
	if spawn_mini_boss_enemy_seconds > 0.0:
		return false
	if spawn_boss_enemy_seconds > 0.0:
		return false
	return true


func all_enemies_killed() -> bool:
	return all_spawns_complete() and TankHelper.get_alive_enemy_count() == 0


# ----------------------------------------------------------------------------------------------------------------------
var enemy_buffs: Array[IBuff] = [BulletSizeBuff.new(), BulletSpeedBuff.new(), BulletFireIntervalBuff.new(), TankSpeedBuff.new(), TankHpBuff.new()]

func enemy_random_buff(size: int) -> Array[IBuff]:
	size = min(size, 9)
	var buffs: Array[IBuff] = []
	for i in range(size):
		buffs.append(RandomUtils.random_ele(enemy_buffs))
	return buffs