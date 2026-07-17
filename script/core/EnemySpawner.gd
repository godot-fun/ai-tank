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

		var tank_data: TankConfig.TankData = TankConfig.enemy_red_easy if enemies_spawned > 0 && enemies_spawned % 8 == 0 else TankConfig.enemy_easy
		var buff_size := enemies_spawned / 10
		var buffs := enemy_random_buff(buff_size)
		var tank := TankHelper.create_tank_with_buffs(tank_data, spawn_grids[i], search_right, buffs)
		enemy_tank_evolution(tank, buffs)
		enemies_spawned += 1
	pass

func calculate_spawn_interval(time_limit: float) -> void:
	var spawn_window := maxf(time_limit - BattleProgress.SPAWN_FINISH_EARLY_SECONDS, 0.0)
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
	var buffs: Array[IBuff] = []
	for i in range(size):
		buffs.append(RandomUtils.random_ele(buffs))
	return buffs


func enemy_tank_evolution(tank: Tank, buffs: Array[IBuff]) -> void:
	var buff_container := BuffContainer.new()
	buff_container.buffs = buffs
	var bullet_buff_count := buff_container.buff_type_of_size(IBuff.BuffType.BULLET_SPEED)
	bullet_buff_count += buff_container.buff_type_of_size(IBuff.BuffType.BULLET_SIZE)
	bullet_buff_count += buff_container.buff_type_of_size(IBuff.BuffType.BULLET_FIRE_INTERVAL)
	
	var tank_buff_count := buff_container.buff_type_of_size(IBuff.BuffType.TANK_SPEED)
	tank_buff_count += buff_container.buff_type_of_size(IBuff.BuffType.TANK_HP)
	
	var bullet_resource_template := "res://image/bullets/tank/red/{}.png"
	var tank_resource_template := "res://image/characters/red_tank_{}.png"
	var bullet_id := clampi(bullet_buff_count / 2, 1, 4)
	var tank_id := clampi(tank_buff_count, 1, 6)
	
	var bullet_resource := StringUtils.format(bullet_resource_template, bullet_id)
	var tank_resource := StringUtils.format(tank_resource_template, tank_id)
	if tank.bullet_resource == bullet_resource && tank.tank_resource == tank_resource:
		return
	tank.bullet_resource = bullet_resource
	tank.tank_resource = tank_resource
	tank.scale_tank()
	pass