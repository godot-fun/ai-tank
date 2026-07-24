class_name EnemySpawner

@warning_ignore("integer_division")
static var spawn_grids: Array[Vector2i] = [
	Vector2i(0, 0),
	Vector2i((TileConfig.MAP_GRID_WIDTH - TankConfig.enemy_easy.grid_size.x) / 2, 0),
	Vector2i(TileConfig.MAP_GRID_WIDTH - TankConfig.enemy_easy.grid_size.x, 0),
]

const ENEMY_WAVE: Array[int] = [2, 3, 3, 4, 5, 
								4, 5, 5, 6, 7, 
								6, 7, 7, 8, 9,
								8, 9, 9, 10, 11, 
								10, 11, 11, 12, 13, 
								12, 13, 13, 14, 15, 
								14, 15, 15, 16, 17]

const ENEMY_JEEP_WAVE: Array[int] = [1, 1, 1, 2, 2, 
									2, 2, 2, 3, 3,
									3, 3, 3, 4, 4, 
									4, 4, 4, 5, 5, 
									5, 5, 5, 6, 6, 
									6, 6, 6, 7, 7,  
									7, 7, 7, 8, 8]

const ELITE_ENEMY_WAVE: Array[int] = [1, 1, 1, 2, 1, 1, 1, 2, 2, 1
									, 1, 1, 1, 2, 1, 1, 1, 2, 2, 1
									, 1, 1, 1, 2, 1, 1, 1, 2, 2, 1
									, 1, 1, 2, 3, 4]

static var MINI_BOSS_ENEMY_SPAWN_LEVEL: Dictionary[int, TankConfig.TankData] = {
	3: TankConfig.mini_boss_enemy_easy_1,
	8: TankConfig.mini_boss_enemy_easy_1,
	9: TankConfig.mini_boss_enemy_easy_1,
	13: TankConfig.mini_boss_enemy_easy_2,
	18: TankConfig.mini_boss_enemy_easy_2,
	19: TankConfig.mini_boss_enemy_easy_2,
	23: TankConfig.mini_boss_enemy_easy_3,
	28: TankConfig.mini_boss_enemy_easy_3,
	29: TankConfig.mini_boss_enemy_easy_3,
	33: TankConfig.mini_boss_enemy_easy_3,
	34: TankConfig.mini_boss_enemy_easy_3,
}
static var BOSS_ENEMY_SPAWN_LEVEL: Dictionary[int, TankConfig.TankData] = {
	4: TankConfig.boss_enemy_easy_1,
	9: TankConfig.boss_enemy_easy_1,
	14: TankConfig.boss_enemy_easy_1,
	19: TankConfig.boss_enemy_easy_2,
	24: TankConfig.boss_enemy_easy_2,
	29: TankConfig.boss_enemy_easy_2,
	34: TankConfig.boss_enemy_easy_2,
}

const ENEMY_WAVE_SPAWN_INTERVAL := 3.1
const ENEMY_JEEP_WAVE_SPAWN_INTERVAL := 5.3
const ELITE_ENEMY_WAVE_SPAWN_INTERVAL := 7.7

var level: int = 0
var enemies_spawned_wave := 0
var jeep_enemies_spawned_wave := 0
var elite_enemies_spawned_wave := 0
var enemies_killed := 0
var enemy_spawn_timer := 0.0
var enemy_jeep_spawn_timer := 0.0
var elite_enemy_spawn_timer := 0.0
var remaining_time := 0.0
var spawn_mini_boss_enemy_seconds := 0.0
var spawn_boss_enemy_seconds := 0.0


func setup(time_limit: float, _level: int) -> void:
	level = _level
	enemies_spawned_wave = 0
	jeep_enemies_spawned_wave = 0
	elite_enemies_spawned_wave = 0
	enemies_killed = 0
	enemy_spawn_timer = 0.0
	enemy_jeep_spawn_timer = 0.0
	elite_enemy_spawn_timer = 0.0
	remaining_time = time_limit
	
	if MINI_BOSS_ENEMY_SPAWN_LEVEL.has(level):
		spawn_mini_boss_enemy_seconds = time_limit * 0.75
		
	if BOSS_ENEMY_SPAWN_LEVEL.has(level):
		spawn_boss_enemy_seconds = time_limit * 0.7


func spawn_initial_wave() -> void:
	spawn_enemy_wave()


func update(delta: float, time_remaining: float) -> void:
	remaining_time = time_remaining

	if time_remaining < spawn_mini_boss_enemy_seconds:
		spawn_mini_boss_enemy()
		return
	
	if time_remaining < spawn_boss_enemy_seconds:
		spawn_boss_enemy()
		return

	update_enemy_spawn(delta)
	update_enemy_jeep_spawn(delta)
	update_elite_enemy_spawn(delta)


func update_enemy_spawn(delta: float) -> void:
	if enemies_spawned_wave >= get_enemy_wave_count():
		return
	enemy_spawn_timer += delta
	if enemy_spawn_timer >= ENEMY_WAVE_SPAWN_INTERVAL:
		enemy_spawn_timer = 0.0
		spawn_enemy_wave()


func update_enemy_jeep_spawn(delta: float) -> void:
	if jeep_enemies_spawned_wave >= get_enemy_jeep_wave_count():
		return
	enemy_jeep_spawn_timer += delta
	if enemy_jeep_spawn_timer >= ENEMY_JEEP_WAVE_SPAWN_INTERVAL:
		enemy_jeep_spawn_timer = 0.0
		spawn_enemy_jeep_wave()


func update_elite_enemy_spawn(delta: float) -> void:
	if elite_enemies_spawned_wave >= get_elite_enemy_wave_count():
		return
	elite_enemy_spawn_timer += delta
	if elite_enemy_spawn_timer >= ELITE_ENEMY_WAVE_SPAWN_INTERVAL:
		elite_enemy_spawn_timer = 0.0
		spawn_elite_enemy_wave()


# ----------------------------------------------------------------------------------------------------------------------
func spawn_enemy_wave() -> void:
	if enemies_spawned_wave >= get_enemy_wave_count():
		return
	var buff_size := enemies_spawned_wave / 3
	enemies_spawned_wave += 1
	spawn_wave_tanks(TankConfig.enemy_easy, buff_size)


func spawn_enemy_jeep_wave() -> void:
	if jeep_enemies_spawned_wave >= get_enemy_jeep_wave_count():
		return
	var buff_size := jeep_enemies_spawned_wave / 4
	jeep_enemies_spawned_wave += 1
	spawn_wave_tanks(TankConfig.enemy_jeep, buff_size)


func spawn_elite_enemy_wave() -> void:
	if elite_enemies_spawned_wave >= get_elite_enemy_wave_count():
		return
	var buff_size := elite_enemies_spawned_wave / 2
	elite_enemies_spawned_wave += 1
	spawn_wave_tanks(TankConfig.elite_enemy_easy, buff_size)


func spawn_wave_tanks(tank_data: TankConfig.TankData, buff_size: int) -> void:
	for i in range(spawn_grids.size()):
		var buffs := enemy_random_buff(buff_size)
		var tank := TankHelper.create_tank_with_buffs(tank_data, spawn_grids[i], buffs)
		if tank == null:
			continue
		BuffManager.update_tank_appearance(tank, buffs)


func spawn_mini_boss_enemy() -> void:
	var tank_data: TankConfig.TankData = MINI_BOSS_ENEMY_SPAWN_LEVEL[level]
	var buff_size: int= BattleProgress.level / 4
	var buffs := enemy_random_buff(buff_size)
	var tank := TankHelper.create_tank_with_buffs(tank_data, spawn_grids[1], buffs)
	if tank == null:
		return
	tank.scale_tank()
	tank.hp = tank.hp + BattleProgress.level * 5
	spawn_mini_boss_enemy_seconds = 0
	Audio.play_music(AudioConfig.BGM_FC_BOSS_BATTLE)
	SchedulerBus.schedule(spawn_enemy_wave, 1000)
	pass
	
func spawn_boss_enemy() -> void:
	var tank_data: TankConfig.TankData = BOSS_ENEMY_SPAWN_LEVEL[level]
	var buff_size: int= BattleProgress.level / 3
	var buffs := enemy_random_buff(buff_size)
	var tank := TankHelper.create_tank_with_buffs(tank_data, spawn_grids[1], buffs)
	if tank == null:
		return
	var tank_resources := ["res://image/characters/red_tank_7.png", "res://image/characters/red_tank_8.png"]
	var tank_resource: String = RandomUtils.random_ele(tank_resources)
	tank.tank_resource = tank_resource
	tank.scale_tank()
	tank.hp = tank.hp + BattleProgress.level * 6
	spawn_boss_enemy_seconds = 0
	Audio.play_music(AudioConfig.BGM_BOSS_BATTLE)
	SchedulerBus.schedule(spawn_enemy_wave, 1000)
	pass
# ----------------------------------------------------------------------------------------------------------------------
func get_waves_spawned() -> int:
	return enemies_spawned_wave + jeep_enemies_spawned_wave + elite_enemies_spawned_wave


func get_enemy_wave_count() -> int:
	return ENEMY_WAVE[min(level, ENEMY_WAVE.size() - 1)]


func get_enemy_jeep_wave_count() -> int:
	return ENEMY_JEEP_WAVE[min(level, ENEMY_JEEP_WAVE.size() - 1)]


func get_elite_enemy_wave_count() -> int:
	return ELITE_ENEMY_WAVE[min(level, ELITE_ENEMY_WAVE.size() - 1)]


func get_total_enemy_wave_count() -> int:
	return get_enemy_wave_count() + get_enemy_jeep_wave_count() + get_elite_enemy_wave_count()


func get_total_enemies() -> int:
	var total := get_total_enemy_wave_count() * spawn_grids.size()
	if MINI_BOSS_ENEMY_SPAWN_LEVEL.has(level):
		total += 1
	if BOSS_ENEMY_SPAWN_LEVEL.has(level):
		total += 1
	return total


func on_enemy_tank_death() -> void:
	enemies_killed += 1


func get_remaining_count() -> int:
	return get_total_enemies() - enemies_killed


func get_remaining_wave_count() -> int:
	return get_total_enemy_wave_count() - get_waves_spawned()


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
	size = min(size, 12)
	var buffs: Array[IBuff] = []
	for i in range(size):
		buffs.append(RandomUtils.random_ele(enemy_buffs))
	return buffs
