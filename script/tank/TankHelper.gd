class_name TankHelper

const TANK_SCENE := "res://scene/Tank.tscn"

static var tanks: Array[Tank] = []


static func get_alive_enemy_count() -> int:
	var count := 0
	for tank in tanks:
		if tank.is_alive_enemy():
			count += 1
	return count


# 从 grid 出发，向左右交替扩展，寻找最近可放置 grid_size 的格子；找不到返回 Vector2i.MIN
static func find_spawn_grid(grid: Vector2i, grid_size: Vector2i) -> Vector2i:
	if not is_move_blocked(grid, grid_size):
		return grid

	var max_x := TileConfig.MAP_GRID_WIDTH - grid_size.x
	var max_offset := maxi(grid.x, max_x - grid.x)  # 左右各自最多能偏移的格数

	for offset in range(1, max_offset + 1):
		# 同一距离下先查左侧，再查右侧
		var left_x := grid.x - offset
		if left_x >= 0:
			var left := Vector2i(left_x, grid.y)
			if not is_move_blocked(left, grid_size):
				return left

		var right_x := grid.x + offset
		if right_x <= max_x:
			var right := Vector2i(right_x, grid.y)
			if not is_move_blocked(right, grid_size):
				return right

	return Vector2i.MIN


static func create_tank(data: TankConfig.TankData, grid: Vector2i) -> Tank:
	var buff_container := BuffManager.get_buff_container(data.id)
	return create_tank_with_buffs(data, grid, buff_container.buffs)

static func create_tank_with_buffs(data: TankConfig.TankData, grid: Vector2i, buffs: Array[IBuff] = []) -> Tank:
	var spawn_grid := find_spawn_grid(grid, data.grid_size)
	if spawn_grid == Vector2i.MIN:
		return null
	var scene: PackedScene = load(TANK_SCENE)
	var script: Script = TankAgentManager.resolve_script(data)
	var tank: Tank = scene.instantiate()
	tank.set_script(script)
	tank.apply_data(data, spawn_grid)
	tank.name = StringUtils.format("{}_{}_{}", TankConfig.Team.keys()[data.team], spawn_grid.x, spawn_grid.y)

	var parent: Node = (Engine.get_main_loop() as SceneTree).current_scene
	parent.add_child(tank)
	
	BuffManager.trigger_buffs(tank, buffs)

	tank.play_enter_animation()
	return tank

# ----------------------------------------------------------------------------------------------------------------------
static func register_tank(tank: Tank) -> void:
	tanks.append(tank)
	pass


static func unregister_tank(tank: Tank) -> void:
	tanks.erase(tank)
	pass


static func find_player() -> Tank:
	for tank in tanks:
		if tank.team == TankConfig.Team.PLAYER:
			return tank
	return null


static func find_nearest_enemy(from_tank: Tank) -> Tank:
	var nearest: Tank = null
	var nearest_dist := INF

	for tank in tanks:
		if !tank.is_alive_enemy():
			continue
		var dist := absi(from_tank.grid_pos.x - tank.grid_pos.x) + absi(from_tank.grid_pos.y - tank.grid_pos.y)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = tank

	return nearest

static func is_move_blocked(grid: Vector2i, grid_size: Vector2i, exclude: Tank = null) -> bool:
	if not TileConfig.is_in_bounds(grid, grid_size):
		return true
	if TileHelper.is_area_blocked_for_tank(grid, grid_size):
		return true
	if is_area_blocked_by_tank(grid, grid_size, exclude):
		return true
	return false


static func is_area_blocked_by_tank(grid: Vector2i, grid_size: Vector2i, exclude: Tank = null) -> bool:
	for tank in tanks:
		if tank == exclude:
			continue
		if grid.x < tank.grid_pos.x + tank.grid_size.x and grid.x + grid_size.x > tank.grid_pos.x \
			and grid.y < tank.grid_pos.y + tank.grid_size.y and grid.y + grid_size.y > tank.grid_pos.y:
			return true
	return false


static func is_area_blocked_by_player_tank(grid: Vector2i, grid_size: Vector2i, exclude: Tank = null) -> bool:
	for tank in tanks:
		if tank == exclude:
			continue
		if TankConfig.is_enemy_faction(tank.team):
			continue
		if grid.x < tank.grid_pos.x + tank.grid_size.x and grid.x + grid_size.x > tank.grid_pos.x \
			and grid.y < tank.grid_pos.y + tank.grid_size.y and grid.y + grid_size.y > tank.grid_pos.y:
			return true
	return false
