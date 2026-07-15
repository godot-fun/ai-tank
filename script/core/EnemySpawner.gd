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


func setup(total: int, time_limit: float) -> void:
	total_enemies = total
	enemies_spawned = 0
	enemies_killed = 0
	spawn_timer = 0.0

	var wave_count := ceili(float(total) / float(spawn_grids.size()))
	if wave_count <= 1:
		spawn_interval = time_limit
	else:
		spawn_interval = time_limit / float(wave_count - 1)


func spawn_initial_wave() -> void:
	spawn_wave()


func update(delta: float) -> void:
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		spawn_wave()


func spawn_wave() -> void:
	if enemies_spawned >= total_enemies:
		return

	for grid in spawn_grids:
		if enemies_spawned >= total_enemies:
			break
		if try_spawn_at(grid):
			enemies_spawned += 1


func try_spawn_at(grid: Vector2i) -> bool:
	var grid_size := TankConfig.enemy_easy.grid_size
	if TankHelper.is_move_blocked(grid, grid_size):
		return false

	var tank_data: TankConfig.TankData = TankConfig.enemy_red_easy if enemies_spawned > 0 && enemies_spawned % 8 == 0 else TankConfig.enemy_easy
	TankHelper.create_tank(tank_data, grid)
	return true


func on_enemy_tank_death() -> void:
	enemies_killed += 1


func get_remaining_count() -> int:
	return total_enemies - enemies_killed


func all_enemies_killed() -> bool:
	return enemies_killed >= total_enemies
