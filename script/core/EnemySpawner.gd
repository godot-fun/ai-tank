class_name EnemySpawner

@warning_ignore("integer_division")
static var spawn_grids: Array[Vector2i] = [
	Vector2i(0, 0),
	Vector2i((TileConfig.MAP_GRID_WIDTH - TankConfig.enemy_easy.grid_size.x) / 2, 0),
	Vector2i(TileConfig.MAP_GRID_WIDTH - TankConfig.enemy_easy.grid_size.x, 0),
]

var total_enemies := 0
var enemies_spawned := 0
var enemies_killed := 0
var spawn_timer := 0.0
var spawn_interval := 0.0
var remaining_time := 0.0


func setup(total: int, time_limit: float) -> void:
	total_enemies = total
	enemies_spawned = 0
	enemies_killed = 0
	spawn_timer = 0.0
	remaining_time = time_limit
	calculate_spawn_interval(time_limit)


func spawn_initial_wave() -> void:
	spawn_wave()


func update(delta: float, time_remaining: float) -> void:
	remaining_time = time_remaining

	if enemies_spawned >= total_enemies:
		return

	if time_remaining <= BattleProgress.SPAWN_FINISH_EARLY_SECONDS:
		spawn_wave()
		return

	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		spawn_wave()


func spawn_wave() -> void:
	if enemies_spawned >= total_enemies:
		return

	for i in range(spawn_grids.size()):
		if enemies_spawned >= total_enemies:
			break
		var search_right := i == 0
		if try_spawn_at(spawn_grids[i], search_right):
			enemies_spawned += 1


func calculate_spawn_interval(time_limit: float) -> void:
	var spawn_window := maxf(time_limit - BattleProgress.SPAWN_FINISH_EARLY_SECONDS, 0.0)
	var total_waves := ceili(float(total_enemies) / float(spawn_grids.size()))
	if total_waves <= 1:
		spawn_interval = spawn_window
	else:
		spawn_interval = spawn_window / float(total_waves - 1)


func try_spawn_at(grid: Vector2i, search_right: bool = false) -> bool:
	var tank_data: TankConfig.TankData = TankConfig.enemy_red_easy if enemies_spawned > 0 && enemies_spawned % 8 == 0 else TankConfig.enemy_easy
	return TankHelper.create_tank(tank_data, grid, search_right) != null


func on_enemy_tank_death() -> void:
	enemies_killed += 1


func get_remaining_count() -> int:
	return total_enemies - enemies_killed


func all_enemies_killed() -> bool:
	return enemies_killed >= total_enemies


# ----------------------------------------------------------------------------------------------------------------------
var enemy_buffs: Array[IBuff] = [BulletSizeBuff.new(), BulletSpeedBuff.new(), BulletFireIntervalBuff.new(), TankSpeedBuff.new(), TankHpBuff.new()]

func enemy_random_buff(size: int) -> Array[IBuff]:
	var buffs: Array[IBuff] = []
	for i in range(size):
		buffs.append(RandomUtils.random_ele(buffs))
	return buffs