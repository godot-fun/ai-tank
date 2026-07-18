class_name EnemySpawner

@warning_ignore("integer_division")
static var spawn_grids: Array[Vector2i] = [
	Vector2i(0, 0),
	Vector2i((TileConfig.MAP_GRID_WIDTH - TankConfig.enemy_easy.grid_size.x) / 2, 0),
	Vector2i(TileConfig.MAP_GRID_WIDTH - TankConfig.enemy_easy.grid_size.x, 0),
]

const INITIAL_ENEMY_COUNT := 10
const ENEMY_COUNT_PER_LEVEL := 5
const RED_ENEMY_SPAWN_INTERVAL := 7

const ELITE_ENEMY_SPAWN_LEVEL: Array[int] = [3, 8, 13, 18, 23, 28, 33]
const BOSS_ENEMY_SPAWN_LEVEL: Array[int] = [4, 9, 14, 19, 24, 29, 34]

var level: int = 0
var total_enemies := 0
var enemies_spawned := 0
var enemies_killed := 0
var spawn_timer := 0.0
var spawn_interval := 0.0
var remaining_time := 0.0
var spawn_finish_early_seconds := 0.0
var spawn_elite_enemy_seconds := 0.0
var spawn_boss_enemy_seconds := 0.0


func setup(time_limit: float, _level: int) -> void:
	level = _level
	enemies_spawned = 0
	enemies_killed = 0
	spawn_timer = 0.0
	remaining_time = time_limit
	spawn_finish_early_seconds = time_limit * 0.5
	
	total_enemies = INITIAL_ENEMY_COUNT + level * ENEMY_COUNT_PER_LEVEL
	
	if ELITE_ENEMY_SPAWN_LEVEL.find(level) >= 0:
		spawn_elite_enemy_seconds = time_limit * 0.6
		
	if BOSS_ENEMY_SPAWN_LEVEL.find(level) >= 0:
		spawn_boss_enemy_seconds = time_limit * 0.6
	
	calculate_spawn_interval(time_limit)


func spawn_initial_wave() -> void:
	spawn_wave()


func update(delta: float, time_remaining: float) -> void:
	remaining_time = time_remaining

	if enemies_spawned >= total_enemies:
		return

	if time_remaining <= spawn_finish_early_seconds:
		spawn_wave()
		return

	if time_remaining <= spawn_elite_enemy_seconds:
		spawn_elite_enemy()
		return
	
	if time_remaining <= spawn_boss_enemy_seconds:
		spawn_boss_enemy()
		return

	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		spawn_wave()


# ----------------------------------------------------------------------------------------------------------------------
func spawn_wave() -> void:
	if enemies_spawned >= total_enemies:
		return

	for i in range(spawn_grids.size()):
		if enemies_spawned >= total_enemies:
			break
		enemies_spawned += 1
		var tank_data: TankConfig.TankData = TankConfig.enemy_easy
		var buff_size := enemies_spawned / 30
		var tank_color := TankConfig.Appearance.gray
		if enemies_spawned % RED_ENEMY_SPAWN_INTERVAL == 0:
			buff_size = enemies_spawned / 10
			tank_data = TankConfig.enemy_red_easy
			tank_color = TankConfig.Appearance.red
		var buffs := enemy_random_buff(buff_size)
		var tank := TankHelper.create_tank_with_buffs(tank_data, spawn_grids[i], buffs)
		if tank == null:
			enemies_spawned -= 1
			return
		BuffManager.update_tank_appearance(tank, buffs, tank_color)
	pass

func spawn_elite_enemy() -> void:
	var tank_data: TankConfig.TankData = TankConfig.elite_enemy_easy
	var buff_size: int= BattleProgress.level / 4
	var buffs := enemy_random_buff(buff_size)
	var tank := TankHelper.create_tank_with_buffs(tank_data, spawn_grids[1], buffs)
	if tank == null:
		return
	var tank_resources := ["res://image/characters/gray_tank_7.png", "res://image/characters/gray_tank_8.png", "res://image/characters/gray_tank_9.png"]
	var tank_resource: String = RandomUtils.random_ele(tank_resources)
	tank.tank_resource = tank_resource
	tank.scale_tank()
	tank.hp = tank.hp + BattleProgress.level
	enemies_spawned += 1
	spawn_elite_enemy_seconds = 0
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
	tank.hp = tank.hp + BattleProgress.level
	enemies_spawned += 1
	spawn_boss_enemy_seconds = 0
	pass
# ----------------------------------------------------------------------------------------------------------------------
func calculate_spawn_interval(time_limit: float) -> void:
	var spawn_window := maxf(time_limit - spawn_finish_early_seconds, 0.0)
	var total_waves := ceili(float(total_enemies) / float(spawn_grids.size()))
	if total_waves <= 1:
		spawn_interval = spawn_window
	else:
		spawn_interval = spawn_window / float(total_waves - 1)


func on_enemy_tank_death() -> void:
	enemies_killed += 1


func get_remaining_count() -> int:
	return total_enemies - enemies_killed


func all_enemies_killed() -> bool:
	return enemies_killed >= total_enemies


# ----------------------------------------------------------------------------------------------------------------------
var enemy_buffs: Array[IBuff] = [BulletSizeBuff.new(), BulletSpeedBuff.new(), BulletFireIntervalBuff.new(), TankSpeedBuff.new(), TankHpBuff.new()]

func enemy_random_buff(size: int) -> Array[IBuff]:
	size = min(size, 9)
	var buffs: Array[IBuff] = []
	for i in range(size):
		buffs.append(RandomUtils.random_ele(enemy_buffs))
	return buffs