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


static func get_enemy_count() -> int:
	return INITIAL_ENEMY_COUNT + BattleProgress.level * ENEMY_COUNT_PER_LEVEL

var total_enemies := 0
var enemies_spawned := 0
var enemies_killed := 0
var spawn_timer := 0.0
var spawn_interval := 0.0
var remaining_time := 0.0
var spawn_finish_early_seconds := 0.0


func setup(total: int, time_limit: float) -> void:
	total_enemies = total
	enemies_spawned = 0
	enemies_killed = 0
	spawn_timer = 0.0
	remaining_time = time_limit
	spawn_finish_early_seconds = time_limit * 0.5
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